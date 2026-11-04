export default [
  {
    files: ["**/*.ts"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
    },
    rules: {
      "no-undef": "error",
      "no-unused-vars": "error",
    },
  },
];
