/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  images: {
    unoptimized: true,
  },
  experimental: {
    outputFileTracingRoot: require('path').join(__dirname),
  },
}

module.exports = nextConfig
