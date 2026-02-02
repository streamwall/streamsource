const js = require('@eslint/js')
const globals = require('globals')

const jsRecommended = {
  ...js.configs.recommended,
  files: ['app/javascript/**/*.js']
}

module.exports = [
  jsRecommended,
  {
    files: ['app/javascript/**/*.js'],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: 'module',
      globals: {
        ...globals.browser,
        Stimulus: 'readonly',
        Turbo: 'readonly',
        ActionCable: 'readonly',
        Rails: 'readonly'
      }
    },
    rules: {
      'no-console': 'warn',
      'no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'prefer-const': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'prefer-template': 'error',
      'template-curly-spacing': 'error',
      'arrow-spacing': 'error',
      'comma-dangle': ['error', 'never'],
      'quotes': ['error', 'single', { avoidEscape: true }],
      'semi': ['error', 'never'],
      'space-before-function-paren': ['error', 'always'],
      'keyword-spacing': 'error',
      'space-infix-ops': 'error',
      'eol-last': 'error',
      'no-trailing-spaces': 'error',
      'indent': ['error', 2],
      'no-multiple-empty-lines': ['error', { max: 1 }],
      'padded-blocks': ['error', 'never'],
      'object-curly-spacing': ['error', 'always'],
      'array-bracket-spacing': ['error', 'never'],
      'computed-property-spacing': ['error', 'never'],
      'func-call-spacing': ['error', 'never'],
      'key-spacing': ['error', { beforeColon: false, afterColon: true }],
      'no-mixed-operators': 'error',
      'no-tabs': 'error',
      'quote-props': ['error', 'as-needed'],
      'space-unary-ops': 'error',
      'spaced-comment': ['error', 'always'],
      'switch-colon-spacing': 'error',
      'unicode-bom': ['error', 'never']
    }
  },
  {
    files: ['**/controllers/**/*.js'],
    rules: {
      'class-methods-use-this': 'off',
      'no-unused-vars': ['error', { args: 'none' }]
    }
  }
]
