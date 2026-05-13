const js = require("@eslint/js");
const globals = require("globals");

module.exports = [
  {
    ignores: ["node_modules/**"],
  },
  js.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: 2018,
      sourceType: "commonjs",
      globals: {
        ...globals.es2018,
        ...globals.node,
      },
    },
    rules: {
      "no-restricted-globals": ["error", "name", "length"],
      "prefer-arrow-callback": "error",
      "quotes": ["error", "double", {"allowTemplateLiterals": true}],
    },
  },
  {
    files: ["**/*.spec.*"],
    languageOptions: {
      globals: {
        ...globals.mocha,
      },
    },
  },
];
