


# Shunting Yard

Turning infix notation to postfix notation (Reverse Polish Notation, RPN):

```coffee
SHUNTINGYARD.parse g, "3 + 4"

[ { s: '3', idx: 1, t: 'number' },
  { s: '4', idx: 5, t: 'number' },
  { s: '+', idx: 3, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "a + 4"

[ { s: 'a', idx: 1, t: 'name' },
  { s: '4', idx: 5, t: 'number' },
  { s: '+', idx: 3, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "3 + b"

[ { s: '3', idx: 1, t: 'number' },
  { s: 'b', idx: 5, t: 'name' },
  { s: '+', idx: 3, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "a + b"

[ { s: 'a', idx: 1, t: 'name' },
  { s: 'b', idx: 5, t: 'name' },
  { s: '+', idx: 3, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "3 + 6 * 7"

[ { s: '3', idx: 1, t: 'number' },
  { s: '6', idx: 5, t: 'number' },
  { s: '7', idx: 9, t: 'number' },
  { s: '*', idx: 7, t: 'operator', a: 'left', p: 2 },
  { s: '+', idx: 3, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "3 * 6 + 7"

[ { s: '3', idx: 1, t: 'number' },
  { s: '6', idx: 5, t: 'number' },
  { s: '*', idx: 3, t: 'operator', a: 'left', p: 2 },
  { s: '7', idx: 9, t: 'number' },
  { s: '+', idx: 7, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "3 * ( 6 + 7 )"

[ { s: '3', idx: 1, t: 'number' },
  { s: '6', idx: 7, t: 'number' },
  { s: '7', idx: 11, t: 'number' },
  { s: '+', idx: 9, t: 'operator', a: 'left', p: 1 },
  { s: '*', idx: 3, t: 'operator', a: 'left', p: 2 } ]
```

```coffee
SHUNTINGYARD.parse g, "() 3 * ( 6 + 7 )"

[ { s: '3', idx: 4, t: 'number' },
  { s: '6', idx: 10, t: 'number' },
  { s: '7', idx: 14, t: 'number' },
  { s: '+', idx: 12, t: 'operator', a: 'left', p: 1 },
  { s: '*', idx: 6, t: 'operator', a: 'left', p: 2 } ]
```

```coffee
SHUNTINGYARD.parse g, "(3) * ( 6 + 7 )"

[ { s: '3', idx: 2, t: 'number' },
  { s: '6', idx: 9, t: 'number' },
  { s: '7', idx: 13, t: 'number' },
  { s: '+', idx: 11, t: 'operator', a: 'left', p: 1 },
  { s: '*', idx: 5, t: 'operator', a: 'left', p: 2 } ]
```

```coffee
SHUNTINGYARD.parse g, "3*6^7"

[ { s: '3', idx: 1, t: 'number' },
  { s: '6', idx: 3, t: 'number' },
  { s: '7', idx: 5, t: 'number' },
  { s: '^', idx: 4, t: 'operator', a: 'right', p: 3 },
  { s: '*', idx: 2, t: 'operator', a: 'left', p: 2 } ]
```

```coffee
SHUNTINGYARD.parse g, "6^7*3"

[ { s: '6', idx: 1, t: 'number' },
  { s: '7', idx: 3, t: 'number' },
  { s: '^', idx: 2, t: 'operator', a: 'right', p: 3 },
  { s: '3', idx: 5, t: 'number' },
  { s: '*', idx: 4, t: 'operator', a: 'left', p: 2 } ]
```

```coffee
SHUNTINGYARD.parse g, "6+7+3"

[ { s: '6', idx: 1, t: 'number' },
  { s: '7', idx: 3, t: 'number' },
  { s: '+', idx: 2, t: 'operator', a: 'left', p: 1 },
  { s: '3', idx: 5, t: 'number' },
  { s: '+', idx: 4, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "6^7^3"

[ { s: '6', idx: 1, t: 'number' },
  { s: '7', idx: 3, t: 'number' },
  { s: '3', idx: 5, t: 'number' },
  { s: '^', idx: 4, t: 'operator', a: 'right', p: 3 },
  { s: '^', idx: 2, t: 'operator', a: 'right', p: 3 } ]
```

```coffee
SHUNTINGYARD.parse g, "6 ^ 7 + 3"

[ { s: '6', idx: 1, t: 'number' },
  { s: '7', idx: 5, t: 'number' },
  { s: '^', idx: 3, t: 'operator', a: 'right', p: 3 },
  { s: '3', idx: 9, t: 'number' },
  { s: '+', idx: 7, t: 'operator', a: 'left', p: 1 } ]
```

```coffee
SHUNTINGYARD.parse g, "6 ^ [ 7 + 3 ]"

[ { s: '6', idx: 1, t: 'number' },
  { s: '7', idx: 7, t: 'number' },
  { s: '3', idx: 11, t: 'number' },
  { s: '+', idx: 9, t: 'operator', a: 'left', p: 1 },
  { s: '^', idx: 3, t: 'operator', a: 'right', p: 3 } ]
```

```coffee
SHUNTINGYARD.parse g, "a = 1"

[ { s: 'a', idx: 1, t: 'name' },
  { s: '1', idx: 5, t: 'number' },
  { s: '=', idx: 3, t: 'operator', a: 'right', p: 0 } ]
```

```coffee
SHUNTINGYARD.parse g, "a = b = c + 1"

[ { s: 'a', idx: 1, t: 'name' },
  { s: 'b', idx: 5, t: 'name' },
  { s: 'c', idx: 9, t: 'name' },
  { s: '1', idx: 13, t: 'number' },
  { s: '+', idx: 11, t: 'operator', a: 'left', p: 1 },
  { s: '=', idx: 7, t: 'operator', a: 'right', p: 0 },
  { s: '=', idx: 3, t: 'operator', a: 'right', p: 0 } ]
```

```coffee
SHUNTINGYARD.parse g, "g = ( a + b ) * c ^ ( d - e )"

[ { s: 'g', idx: 1, t: 'name' },
  { s: 'a', idx: 7, t: 'name' },
  { s: 'b', idx: 11, t: 'name' },
  { s: '+', idx: 9, t: 'operator', a: 'left', p: 1 },
  { s: 'c', idx: 17, t: 'name' },
  { s: 'd', idx: 23, t: 'name' },
  { s: 'e', idx: 27, t: 'name' },
  { s: '-', idx: 25, t: 'operator', a: 'left', p: 1 },
  { s: '^', idx: 19, t: 'operator', a: 'right', p: 3 },
  { s: '*', idx: 15, t: 'operator', a: 'left', p: 2 },
  { s: '=', idx: 3, t: 'operator', a: 'right', p: 0 } ]
```

