#!/usr/bin/env python3
"""
Railway GraphQL API Client for Hermes Agent (Windows compatible).
Usage: python railway_api.py <command> [args...]

Commands:
  projects                    - List projects
  services <project_id>       - List services in project
  variables <service_id>      - List variables for service
  set-variable <service_id> <key> <value>  - Set a variable
  deploy <service_id>         - Trigger deploy
  logs <service_id> [--tail N] - Get logs
  service-info <service_id>   - Get service details
"""

import os
import sys
import json
import requests
from typing import Optional, Dict, Any, List

GRAPHQL_ENDPOINT = "https://backboard.railway.app/graphql/v2"

class RailwayClient:
    def __init__(self, token: Optional[str] = None):
        self.token = token or os.environ.get("RAILWAY_TOKEN")
        if not self.token:
            raise ValueError("RAILWAY_TOKEN environment variable not set. Get it from Railway Dashboard → Account → Tokens")
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def _request(self, query: str, variables: Dict = None) -> Dict:
        resp = requests.post(
            GRAPHQL_ENDPOINT,
            headers=self.headers,
            json={"query": query, "variables": variables or {}}
        )
        resp.raise_for_status()
        data = resp.json()
        if "errors" in data:
            raise RuntimeError(f"GraphQL errors: {json.dumps(data['errors'], indent=2)}")
        return data.get("data", {})

    # ── Queries ──────────────────────────────────────────────
    def list_projects(self) -> List[Dict]:
        query = """
        query {
            projects {
                edges {
                    node {
                        id
                        name
                        description
                        createdAt
                    }
                }
            }
        }
        """
        data = self._request(query)
        return [e["node"] for e in data.get("projects", {}).get("edges", [])]

    def list_services(self, project_id: str) -> List[Dict]:
        query = """
        query($projectId: String!) {
            project(id: $projectId) {
                services {
                    edges {
                        node {
                            id
                            name
                            createdAt
                        }
                    }
                }
            }
        }
        """
        data = self._request(query, {"projectId": project_id})
        return [e["node"] for e in data.get("project", {}).get("services", {}).get("edges", [])]

    def get_service(self, service_id: str) -> Dict:
        query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                id
                name
                projectId
                createdAt
            }
        }
        """
        data = self._request(query, {"serviceId": service_id})
        return data.get("service", {})

    def list_variables(self, service_id: str) -> List[Dict]:
        # Get projectId first
        project_query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                projectId
            }
        }
        """
        project_data = self._request(project_query, {"serviceId": service_id})
        project_id = project_data.get("service", {}).get("projectId")
        if not project_id:
            raise ValueError(f"Could not get projectId for service {service_id}")

        # Query project environments and variables
        query = """
        query($projectId: String!) {
            project(id: $projectId) {
                environments {
                    edges {
                        node {
                            id
                            name
                            variables {
                                edges {
                                    node {
                                        id
                                        name
                                        environmentId
                                        serviceId
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """
        data = self._request(query, {"projectId": project_id})
        variables = []
        for env in data.get("project", {}).get("environments", {}).get("edges", []):
            for var in env["node"]["variables"]["edges"]:
                if var["node"].get("serviceId") == service_id:
                    # Return in key/value format for compatibility
                    variables.append({
                        "key": var["node"]["name"],
                        "value": "",  # Value not directly exposed in this API
                        "id": var["node"]["id"],
                        "environmentId": var["node"]["environmentId"]
                    })
        return variables

    def set_variable(self, service_id: str, key: str, value: str) -> Dict:
        # Need to get projectId and environmentId first
        # Query the service's project and environment
        project_query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                projectId
            }
        }
        """
        project_data = self._request(project_query, {"serviceId": service_id})
        project_id = project_data.get("service", {}).get("projectId")
        if not project_id:
            raise ValueError(f"Could not get projectId for service {service_id}")

        # Get the production environment for the project
        env_query = """
        query($projectId: String!) {
            project(id: $projectId) {
                environments {
                    edges {
                        node {
                            id
                            name
                        }
                    }
                }
            }
        }
        """
        env_data = self._request(env_query, {"projectId": project_id})
        environments = env_data.get("project", {}).get("environments", {}).get("edges", [])
        # Find production environment
        env_id = None
        for env in environments:
            if env["node"]["name"] == "production":
                env_id = env["node"]["id"]
                break
        if not env_id and environments:
            env_id = environments[0]["node"]["id"]  # fallback to first
        if not env_id:
            raise ValueError(f"Could not find environment for project {project_id}")

        mutation = """
        mutation($input: VariableUpsertInput!) {
            variableUpsert(input: $input)
        }
        """
        data = self._request(mutation, {
            "input": {
                "projectId": project_id,
                "environmentId": env_id,
                "serviceId": service_id,
                "name": key,
                "value": value
            }
        })
        return {"success": data.get("variableUpsert", False)}

    def delete_variable(self, service_id: str, key: str) -> bool:
        # Need projectId and environmentId
        project_query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                projectId
            }
        }
        """
        project_data = self._request(project_query, {"serviceId": service_id})
        project_id = project_data.get("service", {}).get("projectId")
        if not project_id:
            raise ValueError(f"Could not get projectId for service {service_id}")

        # Get the production environment for the project
        env_query = """
        query($projectId: String!) {
            project(id: $projectId) {
                environments {
                    edges {
                        node {
                            id
                            name
                        }
                    }
                }
            }
        }
        """
        env_data = self._request(env_query, {"projectId": project_id})
        environments = env_data.get("project", {}).get("environments", {}).get("edges", [])
        env_id = None
        for env in environments:
            if env["node"]["name"] == "production":
                env_id = env["node"]["id"]
                break
        if not env_id and environments:
            env_id = environments[0]["node"]["id"]
        if not env_id:
            raise ValueError(f"Could not find environment for project {project_id}")

        mutation = """
        mutation($input: VariableDeleteInput!) {
            variableDelete(input: $input)
        }
        """
        data = self._request(mutation, {
            "input": {
                "projectId": project_id,
                "environmentId": env_id,
                "serviceId": service_id,
                "name": key
            }
        })
        return data.get("variableDelete", False)

    def deploy(self, service_id: str) -> Dict:
        # Need projectId and environmentId
        project_query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                projectId
            }
        }
        """
        project_data = self._request(project_query, {"serviceId": service_id})
        project_id = project_data.get("service", {}).get("projectId")
        if not project_id:
            raise ValueError(f"Could not get projectId for service {service_id}")

        # Get the production environment for the project
        env_query = """
        query($projectId: String!) {
            project(id: $projectId) {
                environments {
                    edges {
                        node {
                            id
                            name
                        }
                    }
                }
            }
        }
        """
        env_data = self._request(env_query, {"projectId": project_id})
        environments = env_data.get("project", {}).get("environments", {}).get("edges", [])
        env_id = None
        for env in environments:
            if env["node"]["name"] == "production":
                env_id = env["node"]["id"]
                break
        if not env_id and environments:
            env_id = environments[0]["node"]["id"]
        if not env_id:
            raise ValueError(f"Could not find environment for project {project_id}")

        mutation = """
        mutation($serviceId: String!, $environmentId: String!) {
            serviceInstanceRedeploy(serviceId: $serviceId, environmentId: $environmentId)
        }
        """
        data = self._request(mutation, {"serviceId": service_id, "environmentId": env_id})
        return {"success": data.get("serviceInstanceRedeploy", False)}

    def get_logs(self, service_id: str, tail: int = 100) -> List[Dict]:
        # Need to get the environment ID for the service's project
        project_query = """
        query($serviceId: String!) {
            service(id: $serviceId) {
                projectId
            }
        }
        """
        project_data = self._request(project_query, {"serviceId": service_id})
        project_id = project_data.get("service", {}).get("projectId")
        if not project_id:
            raise ValueError(f"Could not get projectId for service {service_id}")

        # Get the production environment for the project
        env_query = """
        query($projectId: String!) {
            project(id: $projectId) {
                environments {
                    edges {
                        node {
                            id
                            name
                        }
                    }
                }
            }
        }
        """
        env_data = self._request(env_query, {"projectId": project_id})
        environments = env_data.get("project", {}).get("environments", {}).get("edges", [])
        env_id = None
        for env in environments:
            if env["node"]["name"] == "production":
                env_id = env["node"]["id"]
                break
        if not env_id and environments:
            env_id = environments[0]["node"]["id"]
        if not env_id:
            raise ValueError(f"Could not find environment for project {project_id}")

        # Query environment logs
        query = """
        query($environmentId: String!, $afterLimit: Int!) {
            environmentLogs(environmentId: $environmentId, afterLimit: $afterLimit) {
                timestamp
                message
                severity
            }
        }
        """
        data = self._request(query, {"environmentId": env_id, "afterLimit": tail})
        return data.get("environmentLogs", [])


def print_json(data):
    print(json.dumps(data, indent=2, ensure_ascii=False))


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]
    client = RailwayClient()

    try:
        if cmd == "projects":
            print_json(client.list_projects())

        elif cmd == "services":
            if len(sys.argv) < 3:
                print("Usage: railway_api.py services <project_id>")
                sys.exit(1)
            print_json(client.list_services(sys.argv[2]))

        elif cmd == "service-info":
            if len(sys.argv) < 3:
                print("Usage: railway_api.py service-info <service_id>")
                sys.exit(1)
            print_json(client.get_service(sys.argv[2]))

        elif cmd == "variables":
            if len(sys.argv) < 3:
                print("Usage: railway_api.py variables <service_id>")
                sys.exit(1)
            print_json(client.list_variables(sys.argv[2]))

        elif cmd == "set-variable":
            if len(sys.argv) < 5:
                print("Usage: railway_api.py set-variable <service_id> <key> <value>")
                sys.exit(1)
            _, _, sid, key, value = sys.argv[:5]
            print_json(client.set_variable(sid, key, value))

        elif cmd == "delete-variable":
            if len(sys.argv) < 4:
                print("Usage: railway_api.py delete-variable <service_id> <key>")
                sys.exit(1)
            result = client.delete_variable(sys.argv[2], sys.argv[3])
            print_json({"deleted": result})

        elif cmd == "deploy":
            if len(sys.argv) < 3:
                print("Usage: railway_api.py deploy <service_id>")
                sys.exit(1)
            print_json(client.deploy(sys.argv[2]))

        elif cmd == "logs":
            if len(sys.argv) < 3:
                print("Usage: railway_api.py logs <service_id> [--tail N]")
                sys.exit(1)
            sid = sys.argv[2]
            tail = 100
            if "--tail" in sys.argv:
                idx = sys.argv.index("--tail")
                if idx + 1 < len(sys.argv):
                    tail = int(sys.argv[idx + 1])
            print_json(client.get_logs(sid, tail))

        else:
            print(f"Unknown command: {cmd}")
            print(__doc__)
            sys.exit(1)

    except requests.HTTPError as e:
        print(f"HTTP Error: {e.response.status_code} - {e.response.text}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()