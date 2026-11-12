import { describe, expect, it } from 'vitest'
import { PARTNERSHIPS, PARTNERSHIP_TARGETS } from './partnerships'

describe('partnership directory import', () => {
  it('imports the 35 named organizations from the source document', () => {
    expect(PARTNERSHIPS).toHaveLength(36)
  })

  it('keeps the source category totals', () => {
    expect(PARTNERSHIPS.filter((partner) => partner.category === 'empresa')).toHaveLength(13)
    expect(PARTNERSHIPS.filter((partner) => partner.category === 'clinica')).toHaveLength(14)
    expect(PARTNERSHIPS.filter((partner) => partner.category === 'pilates')).toHaveLength(9)
  })

  it('does not invent an agreed frequency or an active partnership', () => {
    expect(PARTNERSHIPS.every((partner) => partner.frequency === null)).toBe(true)
    expect(PARTNERSHIPS.every((partner) => partner.status === 'por_contactar')).toBe(true)
  })

  it('keeps senior talk segments separate from named partner records', () => {
    expect(PARTNERSHIP_TARGETS).toHaveLength(2)
    expect(PARTNERSHIP_TARGETS.every((target) => target.status === 'segmento_sem_entidades_identificadas')).toBe(true)
  })

  it('uses unique stable IDs', () => {
    expect(new Set(PARTNERSHIPS.map((partner) => partner.id)).size).toBe(PARTNERSHIPS.length)
  })
})
