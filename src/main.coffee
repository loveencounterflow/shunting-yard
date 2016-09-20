


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'SHUNTING-YARD'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
alert                     = CND.get_logger 'alert',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
NCR                       = require 'ncr'
LTSORT                    = require 'ltsort'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@new_grammar = ->
  R                     = {}
  R._operator_topograph = LTSORT.new_graph loners: no
  R.operators           = {}
  R.lbrackets           = {}
  R.rbrackets           = {}
  return R


#===========================================================================================================
# TOKENS
#-----------------------------------------------------------------------------------------------------------
@new_token = ( me, symbol, cu_idx ) ->
  type  = @_type_of_symbol me, symbol
  ### `t` for 'type' ###
  R     = { s: symbol, idx: cu_idx, t: type, }
  switch type
    when 'operator'
      operator  = @_operator_from_symbol me, symbol
      R.a       = operator.a
      R.p       = operator.p
  return R

#-----------------------------------------------------------------------------------------------------------
@_symbol_is_whitespace  = ( me, symbol ) -> ( /^\s*$/ ).test symbol
@_symbol_is_number      = ( me, symbol ) -> ( /^[0-9]+$/ ).test symbol
@_symbol_is_operator    = ( me, symbol ) -> symbol of me.operators
@_symbol_is_lbracket    = ( me, symbol ) -> symbol of me.lbrackets
@_symbol_is_rbracket    = ( me, symbol ) -> symbol of me.rbrackets
# @_symbol_is_name        = ( me, symbol ) -> ( not @isa_whitespace symbol ) and ( not @isa_number symbol )
# @_symbol_is_literal     = ( me, symbol ) -> ( @isa_number symbol ) or ( @isa_text symbol )

#-----------------------------------------------------------------------------------------------------------
@_type_of_symbol = ( me, symbol ) ->
  return 'whitespace' if @_symbol_is_whitespace me, symbol
  return 'number'     if @_symbol_is_number     me, symbol
  return 'operator'   if @_symbol_is_operator   me, symbol
  return 'lbracket'   if @_symbol_is_lbracket   me, symbol
  return 'rbracket'   if @_symbol_is_rbracket   me, symbol
  return 'name'

#-----------------------------------------------------------------------------------------------------------
@tokenize = ( me, source ) ->
  R       = []
  chrs    = NCR.chrs_from_text source
  cu_idx  = 1
  for symbol in chrs
    R.push @new_token me, symbol, cu_idx
    ### we're counting JS code units here ###
    cu_idx += symbol.length
  return R


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@add_brackets = ( me, left_symbol, right_symbol ) ->
  throw new Error "### MEH ###" if me.lbrackets[   left_symbol ]?
  throw new Error "### MEH ###" if me.lbrackets[  right_symbol ]?
  throw new Error "### MEH ###" if me.rbrackets[  left_symbol ]?
  throw new Error "### MEH ###" if me.rbrackets[ right_symbol ]?
  me.lbrackets[   left_symbol ] = right_symbol
  me.rbrackets[ right_symbol ] =  left_symbol
  return null

#-----------------------------------------------------------------------------------------------------------
@_lbracket_from_rbracket = ( me, rbracket ) ->
  key = if ( CND.isa_text rbracket ) then rbracket else rbracket.s
  throw new Error "not a right bracket: #{rpr rbracket}" unless ( R = me.rbrackets[ key ] )?
  return R

#-----------------------------------------------------------------------------------------------------------
@new_operator = ( me, symbol, associativity ) ->
  throw new Error "### MEH ###" if me.operators[ symbol ]?
  associativity          ?= 'left'
  ### NOTE 'associativity' also called 'fixity' (see https://en.wikipedia.org/wiki/Operator_associativity) ###
  ### `s` for 'symbol', `a` for 'associativity', `p` for 'precedence' ###
  R                       = { s: symbol, a: associativity, p: null, }
  me.operators[ symbol ]  = R
  return R

#-----------------------------------------------------------------------------------------------------------
@set_operator_precedence = ( me, hi_symbols, lo_symbols ) ->
  hi_symbols    = [ hi_symbols, ] unless CND.isa_list hi_symbols
  lo_symbols    = [ lo_symbols, ] unless CND.isa_list lo_symbols
  for hi_symbol in hi_symbols
    for lo_symbol in lo_symbols
      hi_symbol = hi_symbol.s unless CND.isa_text hi_symbol
      lo_symbol = lo_symbol.s unless CND.isa_text lo_symbol
      LTSORT.add me._operator_topograph, hi_symbol, lo_symbol
  # unless other_operator collection
  # R = { '~isa': 'operator', symbol, precedence, associativity, }
  return null

#-----------------------------------------------------------------------------------------------------------
@_operator_from_symbol = ( me, symbol ) ->
  unless ( R = me.operators[ symbol ] )?
    throw new Error "symbol not known to be an operator: #{rpr symbol}"
  return R

#-----------------------------------------------------------------------------------------------------------
@compile_operators = ( me ) ->
  LTSORT.linearize me._operator_topograph
  groups = LTSORT.group me._operator_topograph
  for group, group_idx in groups
    for symbol in group
      operator    = me.operators[ symbol ]
      unless operator?
        operator = @new_operator me, symbol
      operator.p = groups.length - group_idx - 1
  return null


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@parse = ( me, source ) ->
  tos     = ->
    throw new Error "emtpy stack" if ( idx = stack.length - 1 ) < 0
    return stack[ idx ]
  #.........................................................................................................
  stack   = []
  R       = []
  tokens  = @tokenize me, source
  #.........................................................................................................
  while tokens.length > 0
    token = tokens.shift()
    #.......................................................................................................
    switch type = token.t
      #.....................................................................................................
      when 'whitespace'
        continue
      #.....................................................................................................
      when 'number', 'name'
        R.push token
      #.....................................................................................................
      when 'lbracket'
        stack.push token
      #.....................................................................................................
      when 'rbracket'
        ###
        If the token is a left parenthesis (i.e. "("), then push it onto the stack.
        If the token is a right parenthesis (i.e. ")"):
        Until the token at the top of the stack is a left parenthesis, pop operators off the stack onto the output queue.
        Pop the left parenthesis from the stack, but not onto the output queue.
        If the token at the top of the stack is a function token, pop it onto the output queue.
        If the stack runs out without finding a left parenthesis, then there are mismatched parentheses.
        ###
        lbracket = @_lbracket_from_rbracket me, token
        loop
          throw new Error "### MEH ###" unless stack.length > 0
          token_2 = stack.pop()
          unless token_2.s is lbracket
            R.push token_2
            continue
          # R.push token_2
          break
      #.....................................................................................................
      when 'operator'
        loop
          break unless stack.length > 0
          break unless ( token_2 = tos() ).t is 'operator'
          break unless ( ( token.a is 'left' ) and ( token.p <= token_2.p ) ) or ( ( token.a is 'right' ) and ( token.p <  token_2.p ) )
          R.push stack.pop()
        stack.push token
      #.....................................................................................................
      else
        throw new Error "unsuppported or unknown token type #{rpr type}"
    #.......................................................................................................
    # debug ( CND.steel rpr token ), ( CND.orange R ), ( CND.white stack ) #unless @isa_whitespace token
  #.........................................................................................................
  loop
    break unless stack.length > 0
    token = stack.pop()
    throw new Error "illegal token on stack: #{rpr token}" if token.t in [ 'lbracket', 'rbracket', ]
    R.push token
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@demo = ->
  ###

  **Usage**. First create a new grammar object, call it `g`.

  Define operators and their relative precedences implicity with `set_operator_precedence`; all operators
  in the earlier argument take precedence over those in the second.

  Operators that appear for the first time when they appear in one of the arguments to
  `set_operator_precedence` are automatically created and given an associativity (fixity) of `left`;
  therefore, at least those operators that need another associativity should be created explicitly
  before being mentioned in a precedence statement.

  After all operators have been entered and before any parsing is done, call `compile_operators` to
  turn the relative precedence rules into absolute precedence values.

  Add bracket pairs with `add_brackets`.

  Use `parse` to transform an infix expression to a list of tokens in postfix order.

  ###

  g = @new_grammar()
  @new_operator g, '^', 'right'
  @new_operator g, '=', 'right'
  @set_operator_precedence g, [ '*', '/', ], [ '+', '-', ]
  @set_operator_precedence g, [ '+', '-', '/', '*', ], '='
  @set_operator_precedence g, '^', [ '+', '-', '/', '*', ]
  debug g
  @compile_operators g
  @add_brackets g, '(', ')'
  @add_brackets g, '[', ']'
  debug g
  info @tokenize g, "( 4 + 4 ) * 3"
  info '\n' + rpr @parse g, "3 + 4"
  info '\n' + rpr @parse g, "a + 4"
  info '\n' + rpr @parse g, "3 + b"
  info '\n' + rpr @parse g, "a + b"
  info '\n' + rpr @parse g, "3 + 6 * 7"
  info '\n' + rpr @parse g, "3 * 6 + 7"
  info '\n' + rpr @parse g, "3 * ( 6 + 7 )"
  info '\n' + rpr @parse g, "() 3 * ( 6 + 7 )"
  info '\n' + rpr @parse g, "(3) * ( 6 + 7 )"
  info '\n' + rpr @parse g, "3*6^7"
  info '\n' + rpr @parse g, "6^7*3"
  info '\n' + rpr @parse g, "6+7+3"
  info '\n' + rpr @parse g, "6^7^3"
  info '\n' + rpr @parse g, "6 ^ 7 + 3"
  info '\n' + rpr @parse g, "6 ^ [ 7 + 3 ]"
  info '\n' + rpr @parse g, "a = 1"
  info '\n' + rpr @parse g, "a = b = c + 1"
  info '\n' + rpr @parse g, "g = ( a + b ) * c ^ ( d - e )"
  # info '\n' + rpr @parse g, "6 ^ ( 7 + 3 ]"


############################################################################################################
unless module.parent?
  @demo()
