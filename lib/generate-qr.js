#!/usr/bin/env node

import { renderUnicodeCompact } from 'uqr'

const url = process.argv[2]
if (!url) {
  console.error("Please provide a URL as an argument")
  process.exit(1)
}

try {
  const qrCode = renderUnicodeCompact(url)
  console.log('\n```\n' + qrCode + '\n```')
} catch (error) {
  console.error("Error generating QR code:", error)
  process.exit(1)
}
