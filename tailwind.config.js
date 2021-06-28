const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  mode: 'jit',
  purge: [ './src/**/*.html' ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      fontFamily: {
        heading: [ 'Rakkas', 'cursive' ],
        sans: [ 'Work Sans', ...defaultTheme.fontFamily.sans ],
      },
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
