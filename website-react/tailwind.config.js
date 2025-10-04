/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        heading: ['DM Sans', 'sans-serif'],
        accent: ['Poppins', 'sans-serif'],
      },
      colors: {
        primary: {
          DEFAULT: '#04070d',
          50: '#f0f1f2',
          100: '#e0e2e5',
          200: '#c1c5cb',
          300: '#a2a8b1',
          400: '#838b97',
          500: '#04070d',
          600: '#03060b',
          700: '#030509',
          800: '#020407',
          900: '#010305',
        },
        accent: {
          DEFAULT: '#ff3c00',
          50: '#fff5f2',
          100: '#ffebe5',
          200: '#ffd7cc',
          300: '#ffc3b2',
          400: '#ffaf99',
          500: '#ff3c00',
          600: '#cc3000',
          700: '#992400',
          800: '#661800',
          900: '#330c00',
        },
        neon: {
          DEFAULT: '#adff00',
          50: '#f7ffe5',
          100: '#effecb',
          200: '#dffd97',
          300: '#cffc63',
          400: '#bffb2f',
          500: '#adff00',
          600: '#8acc00',
          700: '#679900',
          800: '#456600',
          900: '#223300',
        },
        glass: 'rgba(255, 255, 255, 0.1)',
      },
      animation: {
        'float': 'float 20s infinite ease-in-out',
        'slide-up': 'slideUp 0.5s ease-out',
        'fade-in': 'fadeIn 0.6s ease-out',
        'spin': 'spin 1s linear infinite',
        'pulse-glow': 'pulseGlow 2s infinite',
        'shimmer': 'shimmer 2s infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translate(0, 0) rotate(0deg)' },
          '33%': { transform: 'translate(30px, -30px) rotate(120deg)' },
          '66%': { transform: 'translate(-20px, 20px) rotate(240deg)' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(30px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        spin: {
          from: { transform: 'rotate(0deg)' },
          to: { transform: 'rotate(360deg)' },
        },
        pulseGlow: {
          '0%, 100%': { boxShadow: '0 0 20px rgba(173, 255, 0, 0.5)' },
          '50%': { boxShadow: '0 0 40px rgba(173, 255, 0, 0.8)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-1000px 0' },
          '100%': { backgroundPosition: '1000px 0' },
        },
      },
      backdropBlur: {
        xs: '2px',
      },
    },
  },
  plugins: [],
}
