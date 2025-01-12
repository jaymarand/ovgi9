// Store par levels data
export interface ParLevel {
  department: string;
  store: string;
  sleeves: number;
  caps: number;
  canvases: number;
  totes: number;
  hardlinesRaw: number;
  softlinesRaw: number;
}

export const parLevels: ParLevel[] = [
  { department: '9011', store: 'Tri-County', sleeves: 40, caps: 80, canvases: 12, totes: 21, hardlinesRaw: 20, softlinesRaw: 45 },
  { department: '9012', store: 'Cheviot', sleeves: 10, caps: 20, canvases: 13, totes: 12, hardlinesRaw: 5, softlinesRaw: 5 },
  { department: '9014', store: 'Independence', sleeves: 11, caps: 22, canvases: 11, totes: 13, hardlinesRaw: 10, softlinesRaw: 10 },
  { department: '9015', store: 'Hamilton', sleeves: 10, caps: 20, canvases: 22, totes: 22, hardlinesRaw: 12, softlinesRaw: 12 },
  { department: '9016', store: 'Oakley', sleeves: 21, caps: 42, canvases: 21, totes: 34, hardlinesRaw: 20, softlinesRaw: 20 },
  { department: '9017', store: 'Lebanon', sleeves: 20, caps: 40, canvases: 34, totes: 33, hardlinesRaw: 17, softlinesRaw: 17 },
  { department: '9018', store: 'Loveland', sleeves: 30, caps: 60, canvases: 32, totes: 24, hardlinesRaw: 20, softlinesRaw: 20 },
  { department: '9019', store: 'Bellevue', sleeves: 26, caps: 52, canvases: 22, totes: 26, hardlinesRaw: 15, softlinesRaw: 15 },
  { department: '9020', store: 'Harrison', sleeves: 32, caps: 64, canvases: 35, totes: 55, hardlinesRaw: 12, softlinesRaw: 12 },
  { department: '9021', store: 'Florence', sleeves: 34, caps: 68, canvases: 54, totes: 20, hardlinesRaw: 20, softlinesRaw: 13 },
  { department: '9023', store: 'Batesville', sleeves: 32, caps: 64, canvases: 38, totes: 45, hardlinesRaw: 12, softlinesRaw: 12 },
  { department: '9024', store: 'Fairfield', sleeves: 33, caps: 66, canvases: 86, totes: 12, hardlinesRaw: 20, softlinesRaw: 20 },
  { department: '9025', store: 'Mason', sleeves: 46, caps: 92, canvases: 54, totes: 11, hardlinesRaw: 6, softlinesRaw: 6 },
  { department: '9026', store: 'Beechmont', sleeves: 4, caps: 8, canvases: 76, totes: 25, hardlinesRaw: 18, softlinesRaw: 18 },
  { department: '9027', store: 'Mt. Washington', sleeves: 3, caps: 6, canvases: 54, totes: 56, hardlinesRaw: 6, softlinesRaw: 6 },
  { department: '9029', store: 'Montgomery', sleeves: 44, caps: 88, canvases: 57, totes: 47, hardlinesRaw: 6, softlinesRaw: 6 },
  { department: '9030', store: 'Oxford', sleeves: 56, caps: 112, canvases: 56, totes: 56, hardlinesRaw: 6, softlinesRaw: 6 },
  { department: '9031', store: 'West Chester', sleeves: 43, caps: 86, canvases: 46, totes: 37, hardlinesRaw: 14, softlinesRaw: 14 },
  { department: '9032', store: 'Lawrenceburg', sleeves: 12, caps: 24, canvases: 28, totes: 38, hardlinesRaw: 10, softlinesRaw: 10 },
  { department: '9033', store: 'Deerfield', sleeves: 45, caps: 90, canvases: 51, totes: 19, hardlinesRaw: 20, softlinesRaw: 20 }
];