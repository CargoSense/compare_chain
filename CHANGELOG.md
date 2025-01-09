# CHANGELOG

## v0.6.0 (2025-01-09)

  * Drop official support for Elixir 1.13 and 1.14 (though they should still work)
  * Currently support Elixir 1.15 to 1.18
  * Miscellanea: doc tweaks, renamed LISENCE file, added CODEOWNERS file, etc.

## v0.5.0 (2024-05-22)

  * Allow `===` and `!===` in expressions
  * Improve documentation
  * Fix bug with certain operation chains:
    ```
    compare?(1 < 2 != 3 < 4) #=> true
    compare?(1 < 2 != 3 > 4) #=> true (wrong!)
    ```
  * Improve error message and documentation for invalid expressions
  * [BREAKING] all branches of `and`, `or` and `not` must now contain comparisons
    * Example: `compare?(1 < 2 and true)` used to be ok but is no longer
      allowed because the right argument to `and` doesn't contain a comparison.

## v0.4.0 (2023-09-10)

  * Warn when `compare?/1` is used on a struct

## v0.3.0 (2023-01-28)

  * Allow `==` and `!=` in expressions
  * Allow `Elixir >= 1.13.0`
    * `Macro.prewalker` was introduced in `1.13.0`

## v0.2.0 (2022-11-05)

  * Allow `not` in expressions

## v0.1.0 (2022-11-03)

  * Initial release
