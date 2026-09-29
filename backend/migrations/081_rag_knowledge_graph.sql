-- backend/migrations/081_rag_knowledge_graph.sql
-- Migration 081: Clinical Knowledge Graph Tables for Aura RAG Brain

-- 1. Create rag_entities table
CREATE TABLE IF NOT EXISTS public.rag_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_name VARCHAR(150) NOT NULL UNIQUE,
    entity_type VARCHAR(50) NOT NULL, -- 'ingrediente', 'patologia', 'tratamiento', 'contraindicacion'
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create rag_relations table
CREATE TABLE IF NOT EXISTS public.rag_relations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_entity_id UUID REFERENCES public.rag_entities(id) ON DELETE CASCADE,
    target_entity_id UUID REFERENCES public.rag_entities(id) ON DELETE CASCADE,
    relation_type VARCHAR(80) NOT NULL, -- 'CONTRAINDICADO_CON', 'RECOMENDADO_PARA', 'COMPATIBLE_CON', 'ANULA_A'
    risk_level VARCHAR(20) DEFAULT 'medio',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uk_source_target_relation UNIQUE (source_entity_id, target_entity_id, relation_type)
);

-- 3. Indexes for graph traversal
CREATE INDEX IF NOT EXISTS idx_rag_entities_name ON public.rag_entities (entity_name);
CREATE INDEX IF NOT EXISTS idx_rag_entities_type ON public.rag_entities (entity_type);
CREATE INDEX IF NOT EXISTS idx_rag_relations_source ON public.rag_relations (source_entity_id);
CREATE INDEX IF NOT EXISTS idx_rag_relations_target ON public.rag_relations (target_entity_id);

-- 4. Insert foundational clinical entities and relationships
INSERT INTO public.rag_entities (entity_name, entity_type, description) VALUES
('acido_hialuronico', 'ingrediente', 'Humectante transepidérmico captador de agua'),
('retinol', 'ingrediente', 'Derivado de vitamina A estimulador de colágeno'),
('vitamina_c', 'ingrediente', 'Antioxidante neutralizador de radicales libres'),
('acido_salicilico', 'ingrediente', 'Beta-hidroxiácido lipofílico queratolítico'),
('piel_con_rosacea', 'patologia', 'Eritema cutáneo reactivo vascular'),
('piel_con_acne', 'patologia', 'Unidad pilosebácea inflamada'),
('embarazo', 'contraindicacion', 'Estado gestacional con restricción de retinoides sistémicos/tópicos altos'),
('peeling_quimico_tca', 'tratamiento', 'Exfoliación química dérmica')
ON CONFLICT (entity_name) DO NOTHING;

-- Seed sample clinical graph edges
INSERT INTO public.rag_relations (source_entity_id, target_entity_id, relation_type, risk_level, notes)
SELECT e1.id, e2.id, 'CONTRAINDICADO_CON', 'alto', 'Retinoides y ácidos fuertes en embarazo o eritema activo'
FROM public.rag_entities e1, public.rag_entities e2
WHERE e1.entity_name = 'retinol' AND e2.entity_name = 'embarazo'
ON CONFLICT DO NOTHING;

INSERT INTO public.rag_relations (source_entity_id, target_entity_id, relation_type, risk_level, notes)
SELECT e1.id, e2.id, 'RECOMENDADO_PARA', 'bajo', 'Sinergia de hidratación y barrera'
FROM public.rag_entities e1, public.rag_entities e2
WHERE e1.entity_name = 'acido_hialuronico' AND e2.entity_name = 'piel_con_rosacea'
ON CONFLICT DO NOTHING;
