export const BUSINESSES = [
  {
    code: '001',
    name: 'Serviços terapêuticos',
    market: 'Portugal',
    currencies: ['EUR'],
    description: 'Massagem e serviços terapêuticos.',
    accent: 'violet',
  },
  {
    code: '004',
    name: 'Desconto de eletricidade',
    market: 'Brasil',
    currencies: ['BRL'],
    description: 'Registo de adesões ao desconto de eletricidade.',
    accent: 'amber',
  },
  {
    code: '003',
    name: 'Cursos online',
    market: 'Internacional',
    currencies: ['EUR', 'BRL'],
    description: 'Formação e cursos online internacionais.',
    accent: 'blue',
  },
  {
    code: '005',
    name: 'GFI HUB',
    market: 'Internacional',
    currencies: ['USD', 'BRL'],
    description: 'Área de informação sobre oportunidades GFI HUB.',
    accent: 'emerald',
  },
] as const

export type BusinessCode = (typeof BUSINESSES)[number]['code']

export function isBusinessCode(value: string): value is BusinessCode {
  return BUSINESSES.some((business) => business.code === value)
}
