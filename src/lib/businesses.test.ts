import { describe, expect, it } from 'vitest'
import { BUSINESSES, isBusinessCode } from './businesses'

describe('business registry', () => {
  it('contains the four independent business lines', () => {
    expect(BUSINESSES.map((item) => item.code)).toEqual(['001', '004', '003', '005'])
  })

  it('accepts only registered business codes', () => {
    expect(isBusinessCode('001')).toBe(true)
    expect(isBusinessCode('999')).toBe(false)
  })

  it('keeps currency configuration per business', () => {
    expect(BUSINESSES.find((item) => item.code === '001')?.currencies).toEqual(['EUR'])
    expect(BUSINESSES.find((item) => item.code === '005')?.currencies).toEqual(['USD', 'BRL'])
  })
})