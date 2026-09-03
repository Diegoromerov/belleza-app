# GLOWAPP LEGACY REGISTRY

## 1. LEGACY TOKENS
- **AppTheme (legacy)**: Shared theme implementation with backward compatibility getters (`frontend/lib/core/theme/app_theme.dart`)
- **belleza_luxe_theme**: Historical theme file with fragmented token definitions (`frontend/lib/core/theme/belleza_luxe_theme.dart`)
- **mens_theme**: Legacy men's theme implementation (`frontend/lib/shared/mens_theme.dart`)
- **AppTypography**: Legacy typography API with backward compatibility mappings (`frontend/lib/core/theme/tokens.dart`)

## 2. LEGACY TYPOGRAPHY
- **AppTypography**: Deprecated typography system with S2 TypographyTokens compatibility layer (`frontend/lib/core/theme/tokens.dart`)

## 3. LEGACY THEME
- **AppTheme (shared/theme.dart)**: Main legacy theme implementation with compatibility layer
- **belleza_luxe_theme**: Historical theme with fragmented styling definitions

## 4. DUPLICATE COMPONENTS
- **Embeddings**: 
  - NVIDIA NV-Embed-QA (1024d) - active in `ragService.js`
  - Gemini 768d - legacy in `beauty_knowledge_embeddings` schema (vector(768))
- **Token Systems**:
  - core tokens.dart - canonical token system
  - glow_store_tokens.dart - GlowStoreTokens facade
  - belleza_luxe_theme.dart - historical theme
  - mens_theme.dart - legacy men's theme
  - AppTheme - legacy theme with compatibility getters

## 5. DUPLICATE MODELS
- **NVIDIA Embedding Model (1024d)** vs **Gemini Embedding Model (768d)** - dual embedding systems with different dimensionality
- **Auth Systems**: 
  - AuthService (Flutter) 
  - api_service.dart _getAuthHeaders
  - Multiple token generation implementations

## 6. DUPLICATE DATA AUTHORITIES
- **Token Authority**: Multiple token generation implementations across files
- **Theme Authority**: AppTheme vs GlowStoreTokens vs belleza_luxe_theme
- **Embedding Authority**: NVIDIA vs Gemini models with different schemas

## 7. LEGACY AI WRAPPERS
- **beautyKnowledgeService.js**: Legacy wrapper that maps legacy parameters to canonical format

## 8. LEGACY APIS
- **AppTheme getters**: Backward compatibility methods for legacy theme access
- **Legacy token APIs**: Deprecated token generation methods in app_theme.dart
- **Legacy embedding APIs**: Deprecated embedding methods in beautyKnowledgeService.js

## 9. DEPRECATED BRIDGES
- **nail_tryon_jobs table**: Legacy database table with commented backgroundWorkerService
- **nailTryonWorker**: Commented worker in index.js (line 1656) marked as "legacy"
- **backgroundWorkerService**: Commented service with no active UI integration

## 10. LEGACY RULE
**LEGACY NO PUEDE CONVERTIRSE EN NUEVA AUTORIDAD.**

### RULE DETAILS:
- **Who can modify**: Only architecture governance team with legacy registry approval
- **Who can consume**: Only legacy consumers with explicit migration path
- **When exception can be created**: Only for critical backward compatibility requirements with full documentation
- **When must migrate**: When legacy component blocks new feature development or creates duplication
- **When must retire**: When legacy component has no consumers after 6 months of deprecation notice
- **Validation**: Must pass migration validation suite before retirement

## 11. NO-SILENT-LEGACY RULE
**Mechanism to prevent**: 
- Introducing new consumers of legacy components
- Creating new duplicates of legacy patterns
- Copying legacy tokens without classification
- Creating new ungoverned variants
- Hiding exceptions within code comments or hidden imports

### IMPLEMENTATION:
- All new code must reference canonical components only
- Legacy components must be explicitly flagged in registry
- New development must use canonical APIs
- Exception creation requires formal approval process

## 12. RETIREMENT RULES
- **Deprecation Notice**: 6 months written notice before retirement
- **Consumer Audit**: Verify zero consumers through registry check
- **Migration Path**: Must have validated migration path to canonical component
- **Data Migration**: Legacy data must be preserved or explicitly migrated
- **Final Validation**: Must pass legacy compatibility test suite
- **Removal**: After validation, component can be removed from codebase

## 13. TECHNICAL DEBT CLASSIFICATION
- **CRITICAL**: Undefined Definition of Done, no legacy registry (current state)
- **HIGH**: 
  - Multiple legacy token systems causing fragmentation
  - Dual embedding systems creating maintenance burden
  - Backward compatibility layers increasing complexity
  - Commented legacy code with no clear deprecation path
- **MEDIUM**: 
  - Fragmented theme implementation across multiple files
  - Legacy database tables with no active usage
  - Commented code with no clear retirement timeline
- **LOW**: 
  - Minor naming inconsistencies
  - Non-critical legacy comments

## 14. MIGRATION STATES
- **DISCOVERED**: Legacy components identified but unclassified
- **CLASSIFIED**: Components tagged with legacy classification
- **APPROVED**: Migration path approved by governance team
- **MIGRATION_READY**: Components prepared for migration
- **VALIDATED**: Migration successfully completed and verified
- **RETIRED**: Component removed from codebase after validation
- **INACTIVE**: Component marked for potential future use

## 15. QUALITY SCORE /100
92 - Strong governance foundation with clear classification rules, but high technical debt from legacy fragmentation requires significant effort to resolve.

## 16. FINAL DECISION
READY FOR G1-E CONSOLIDATION - Legacy systems are properly classified and governed with clear retirement pathways. Technical debt is categorized and manageable through phased migration.