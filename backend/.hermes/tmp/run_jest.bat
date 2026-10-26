@echo off
set JWT_SECRET=ci_secret
set NODE_ENV=test
set "PATH=C:\Program Files\Git\bin;%PATH%"
cd /d C:\beauty-app\backend
npx jest --maxWorkers=2 --forceExit > .hermes\plans\jest_backend_output.txt 2>&1
