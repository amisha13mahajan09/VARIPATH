// Authentic Turn-by-Turn Wari Palkhi Highway Route (NH 965)
// Pune Karve Nagar -> Swargate -> Hadapsar -> Dive Ghat -> Saswad -> Jejuri -> Lonand -> Phaltan -> Natepute -> Malshiras -> Velapur -> Wakhari -> Pandharpur Vitthal Temple

export const authenticVariRoute = [
  // 1. Pune Start / MMCOE Karve Nagar / Swargate Area
  [18.4902, 73.8130], // MMCOE Karve Nagar
  [18.4985, 73.8350], // DP Road / Rajaram Bridge
  [18.5020, 73.8560], // Swargate Chowk
  [18.5035, 73.8820], // Pune Solapur Highway Junction
  [18.4980, 73.9350], // Hadapsar Palkhi Stop
  [18.4810, 73.9480], // Phursungi Phata

  // 2. Dive Ghat Section (Ascent & Hairpin Bends)
  [18.4550, 73.9600], // Vadki Nala Base
  [18.4420, 73.9680], // Dive Ghat Hairpin Bend 1
  [18.4350, 73.9750], // Dive Ghat Hairpin Bend 2
  [18.4280, 73.9720], // Dive Ghat Top (Viewpoint)
  [18.3900, 74.0050], // Pargao Rest Stop

  // 3. Saswad Valley
  [18.3550, 74.0220], // Saswad Approach Road
  [18.3440, 74.0300], // Saswad Palkhi Maidan (Major Stay Halt)
  [18.3180, 74.0820], // Sakurdi Phata

  // 4. Jejuri Temple Hill Section
  [18.2800, 74.1500], // Jejuri Ghat Entrance
  [18.2750, 74.1590], // Jejuri Temple City (Deepotsav Ground)
  [18.2250, 74.1950], // Nazare Dam Bypass

  // 5. Valhe & Lonand Nira River Crossing
  [18.1750, 74.2400], // Valhe Palkhi Stop
  [18.1020, 74.2180], // Nira Bridge Approach
  [18.0650, 74.2010], // Nira River Bridge Crossing
  [18.0400, 74.1880], // Lonand Palkhi Ringan Ground

  // 6. Taradgaon & Phaltan
  [17.9780, 74.2600], // Taradgaon Halt
  [17.9850, 74.3400], // Surplus Canal Bridge
  [17.9890, 74.4320], // Phaltan City (Ground)
  [17.9620, 74.4850], // Vidhani Phata

  // 7. Barad & Natepute
  [17.9250, 74.5500], // Barad Stay Halt
  [17.9120, 74.6500], // Dharampuri Phata
  [17.9000, 74.7700], // Natepute Palkhi Ringan Ground

  // 8. Malshiras & Velapur
  [17.8750, 74.8350], // Markalu Phata
  [17.8450, 74.9080], // Malshiras Base Camp
  [17.8100, 74.9650], // Tirhe Ghat
  [17.7850, 75.0150], // Velapur Temple Halt

  // 9. Bhandishegaon & Wakhari
  [17.7400, 75.1200], // Bhandishegaon Stop
  [17.7220, 75.1850], // Pirachi Kuroli
  [17.7050, 75.2200], // Wakhari Ubha Ringan Ground (Final Confluence)

  // 10. Final Approach to Pandharpur Temple
  [17.6920, 75.2650], // Pandharpur Outer Ring Road
  [17.6850, 75.2980], // Chandrabhaga River Ghat Approach
  [17.6775, 75.3278], // Pandharpur Vitthal Temple
];

export const wariMilestones = [
  { name: 'MMCOE Karve Nagar Start', location: [18.4902, 73.8130], desc: 'Wari Flagoff Hub' },
  { name: 'Hadapsar Stay', location: [18.4980, 73.9350], desc: 'Pune Exit Base' },
  { name: 'Dive Ghat Peak', location: [18.4280, 73.9720], desc: 'Challenging Hairpin Ascent' },
  { name: 'Saswad Palkhi Maidan', location: [18.3440, 74.0300], desc: 'Major Night Stay Camp' },
  { name: 'Jejuri Temple City', location: [18.2750, 74.1590], desc: 'Golden Festival Halt' },
  { name: 'Lonand Ringan', location: [18.0400, 74.1880], desc: 'First Horse Ringan Ground' },
  { name: 'Phaltan Sansthan', location: [17.9890, 74.4320], desc: 'Midway Heritage Stop' },
  { name: 'Malshiras Halt', location: [17.8450, 74.9080], desc: 'Solapur District Border' },
  { name: 'Wakhari Ubha Ringan', location: [17.7050, 75.2200], desc: 'Confluence Ringan' },
  { name: 'Pandharpur Temple', location: [17.6775, 75.3278], desc: 'Final Holy Destination' },
];
