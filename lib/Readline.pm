use v6;
use NativeCall;
#
# XXX &cglobal.signature -> (Any $libname, Any $symbol, Any $target-type)
#

=begin pod

=begin NAME

Readline - GNU Readline binding for perl6

=end NAME

=begin SYNOPSIS

    my $readline = Readline.new;
    while my $response = $readline.readline( "prompt here (<cr> to exit)> " ) {
        $readline.add-history( $response ) if $response ~~ /\S/;
        say "[$response]";
    }

=end SYNOPSIS

=begin DESCRIPTION

A thin OO wrapper around the GNU Readline library. It exposes every function that the current Readline library does, along with some of the structs for history and keymap manipulation from the header files, so that you can peek into the internals. Most people will just use the basic C<readline> and C<add-history> functions, but the more advanced keymapping, history and completion bindings are available for use.

Method names are taken verbatim from the GNU Readline library, with one exception. Library calls use '_', Readline methods use '-'. This helps keep the two layers separate, and is a not-so-subtle reminder that you're using perl6 when using the library.

The documentation in the METHODS section is a verbatim paste of the appropriate bits from the GNU Readline documentation, so for further explanation of the methods, especially callbacks and completion, please see the L<GNU Readline> documentation.

Any chapter references in the documentation refer to the GNU Readline or GNU History manual.

=end DESCRIPTION

=begin LIBRARY

By default the Perl 6 module searches for libreadline.so.* and takes the most recent match it can find.

If you're on OS X, it searches for libreadline.*.dylib.
On OpenBSD it searches for libereadline.so.*.

While I'd prefer to use L<LibraryCheck>'s technique of just attempting to link to a library, it doesn't seem to work inside of the C<is native(&func)> attribute. So instead, it defaults to v7 (the current version as of 2018-07-14) and searches for other versions along a fixed set of library paths, taken from bug reports.

I'll eventually put this into a proper library-find method.

=end LIBRARY

=begin METHODS

=item readline( Str $prompt ) returns Str

=item initialize( ) returns int32

    Initialize or re-initialize Readline's internal state. It's not strictly necessary to call this; readline() calls it before reading any input.

=item ding( ) returns int32

    Ring the terminal bell, obeying the setting of C<$bell-style>.

=begin History

These methods let you add, delete and manipulate history entries. See the L<examples/echo.pl6> script for usage.

=item add-history( Str $history )

    Place string C<$history> at the end of the history list. The associated data field (if any) is set to NULL.

=item using-history( )

    Begin a session in which the history functions might be used. This initializes the interactive variables.

    Author's note - C<add-history()> works fine without this call, maybe it's for methods that require state.

=item history-get-history-state( ) returns HISTORY_STATE

    Return a structure describing the current state of the input history.

=item history-set-history-state( HISTORY_STATE $state )

    Set the state of the history list according to C<$state>.

=item add-history-time( Str $timestamp )

    Change the time stamp associated with the most recent history entry to C<$timestamp>.

=item remove-history( int32 $which ) returns HIST_ENTRY

    Remove history entry at offset C<$which> from the history. The removed element is returned so you can free the line, data, and containing structure.

=item free-history-entry( HIST_ENTRY $entry ) returns Str # histdata_t

    Free the history entry C<$entry> and any history library private data associated with it. Returns the application-specific data so the caller can dispose of it.

=item replace-history-entry( int32 $which, Str $line, Str $data ) returns HIST_ENTRY # histdata_t $data ) returns HIST_ENTRY

    Make the history entry at offset C<$which> have C<$line> and C<$data>. This returns the old entry so the caller can dispose of any application-specific data. In the case of an invalid C<$which>, a NULL pointer is returned.

=item clear-history( )

    Clear the history list by deleting all the entries.

=item stifle-history( int32 $max )

    Stifle the history list, remembering only the last C<$max> entries.

=item unstifle-history( )

    Stop stifling the history. This returns the previously-set maximum number of history entries (as set by stifle_history()). The value is positive if the history was stifled, negative if it wasn't.

=item history-is-stifled( ) returns Bool

    Returns True if the history is stifled, False if not. The C version returns non-zero if the history is stifled, this gets converted to a Perl6 boolean.
   
=item history-list( ) returns CArray[HIST_ENTRY]

    Return a NULL terminated array of HIST_ENTRY * which is the current input history. Element 0 of this list is the beginning of time. If there is no history, return NULL.

=item where-history( ) returns int32

    Returns the offset of the current history element.

=item current-history( int32 $which ) returns HIST_ENTRY

    Return the history entry at the position C<$which>, as determined by C<where-history()>. If there is no entry there, return a NULL pointer.

=item history-get( int32 $which ) returns HIST_ENTRY

    Return the history entry at position C<$which>, starting from C<$history_base> (see section 2.4 History Variables). If there is no entry there, or if offset is greater than the history length, return a NULL pointer.

=item history-get-time( HIST_ENTRY $entry ) returns time_t

    Return the time stamp associated with the history entry C<$entry>.

=item history-total-bytes( ) returns int32

    Return the number of bytes that the primary history entries are using. This function returns the sum of the lengths of all the lines in the history.

=item history-set-pos( int32 $pos ) returns int32

    Set the current history offset to C<$pos>, an absolute index into the list. Returns 1 on success, 0 if C<$pos> is less than zero or greater than the number of history entries.

=item previous-history( ) returns HIST_ENTRY

    Back up the current history offset to the previous history entry, and return a pointer to that entry. If there is no previous entry, return a NULL pointer.

=item next-history( ) returns HIST_ENTRY

    Move the current history offset forward to the next history entry, and return the a pointer to that entry. If there is no next entry, return a NULL pointer.

=item history-search( Str $text, int32 $pos ) returns int32

    Search the history for C<$text>, starting at history offset C<$pos>. If direction is less than 0, then the search is through previous entries, otherwise through subsequent entries. If string is found, then the current history index is set to that history entry, and the value returned is the offset in the line of the entry where string was found. Otherwise, nothing is changed, and a -1 is returned.

=item history-search-prefix( Str $prefix, int32 $pos ) returns int32

    Search the history for a line prefixed with C<$prefix>, starting at history offset C<$pos>. The search is anchored: matching lines must begin with C<$prefix>. If direction is less than 0, then the search is through previous entries, otherwise through subsequent entries. If string is found, then the current history index is set to that entry, and the return value is 0. Otherwise, nothing is changed, and a -1 is returned.

=item history-search-pos( Str $text, int32 $pos, int32 $dir ) returns int32

    Search for C<$text> in the history list, starting at C<$pos>, an absolute index into the list. If C<$direction> is negative, the search proceeds backward from C<$pos>, otherwise forward. Returns the absolute index of the history element where C<$text> was found, or -1 otherwise.

=item read-history( Str $filename ) returns int32

    Add the contents of C<$filename> to the history list, a line at a time. If C<$filename> is Empty, then read from `~/.history'. Returns 0 if successful, or errno if not.

=item read-history-range( Str $filename, int32 $from, int32 $to ) returns int32

    Read a range of lines from C<$filename>, adding them to the history list. Start reading at line C<$from> and end at C<$to>. If C<$from> is zero, start at the beginning. If C<$to> is less than C<$from>, then read until the end of the file. If filename is Empty, then read from `~/.history'. Returns 0 if successful, or errno if not.

=item write-history( Str $filename ) returns int32

    Write the current history to C<$filename>, overwriting C<$filename> if necessary. If C<$filename> is NULL, then write the history list to `~/.history'. Returns 0 on success, or errno on a read or write error.

=item append-history( int32 $offset, Str $filename ) returns int32

    Append the elements starting at C<$offset> of the history list to C<$filename>. If C<$filename> is Empty, then append to `~/.history'. Returns 0 on success, or errno on a read or write error.

=item history-truncate-file( Str $filename, int32 $nLines ) returns int32

    Truncate the history file C<$filename>, leaving only the last C<$nLines> lines. If C<$filename> is Empty, then `~/.history' is truncated. Returns 0 on success, or errno on failure.

=item history-expand( Str $string, Pointer[Str] $output ) returns int32

    Expand C<$string>, placing the result into C<$output>, a pointer to a string (see section 1.1 History Expansion). Returns:

    0  If no expansions took place (or, if the only change in the text was the removal of escape characters preceding the history expansion character);
    1  if expansions did take place;
    -1 if there was an error in expansion;
    2  if the returned line should be displayed, but not executed, as with the :p modifier (see section 1.1.3 Modifiers).

    If an error occurred in expansion, then output contains a descriptive error message.

=item history-arg-extract( int32 $first, int32 $last, Str $string ) returns Str

    Extract a string segment consisting of the C<$first> through C<$last> arguments present in C<$string>. Arguments are split using C<history_tokenize()>.

=item get-history-event( Str $string, Pointer[int32] $cIndex, Str $delimiting-quote ) returns Str

    Returns the text of the history event beginning C<$$cIndex> characters into C<$string>.  C<$$cIndex> is modified to point to after the event specifier. At function entry, C<$cIndex> points to the index into string where the history event specification begins. qchar is a character that is allowed to end the event specification in addition to the "normal" terminating characters.

    Editor's note: C<$$cIndex> may be a byte offset into C<$string> rather than a character offset, so Unicode users beware.

    Editor's note - C<$delimiting-quote> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_get_history_event()> instead.

    DELIMITING_QUOTE is a character that is allowed to end the string specification for what to search for in addition to the normal characters `:', ` ', `\t', `\n', and sometimes `?'.

=item history-tokenize( Str $string ) returns CArray[Str]

    Return an array of tokens parsed out of C<$string>, much as the shell might. The tokens are split on the characters in the C<$history_word_delimiters> variable, and shell quoting conventions are obeyed.

=end History

=begin Keymap

These methods let you manipulate the built-in key mappings.

=item make-bare-keymap( ) returns Keymap

    Returns a new, empty keymap. The space for the keymap is allocated with malloc(); the caller should free it by calling rl_free_keymap() when done.

=item copy-keymap( Keymap $map ) returns Keymap

    Return a new keymap which is a copy of C<$map>.

=item make-keymap( ) returns Keymap

    Return a new keymap with the printing characters bound to C<$rl_insert>, the lowercase Meta characters bound to run their equivalents, and the Meta digits bound to produce numeric arguments.

=item discard-keymap( Keymap $map )

    Free the storage associated with the data in C<$map>. The caller should free the pointer to C<$map>.

=item free-keymap( Keymap $map )

    Free all storage associated with C<$map>. This calls C<rl_discard_keymap()> to free subordindate keymaps and macros.

=item get-keymap-by-name( Str $name ) returns Keymap

    Return the keymap matching C<$name>. C<$name> is one which would be supplied in a set keymap inputrc line (see section 1.3 Readline Init File).

=item get-keymap( ) returns Keymap

    Returns the currently active keymap.

=item get-keymap-name( Keymap $map ) returns Str

    Return the name matching C<$map>. name is one which would be supplied in a set keymap inputrc line (see section 1.3 Readline Init File).

=item set-keymap( Keymap $map )

    Makes C<$map> the currently active keymap.

=end Keymap

=begin Callback

These functions let you use L<Readline> as an interactive event loop.

=item callback-handler-install( Str $prompt, &callback (Str) )

    Set up the terminal for readline I/O and display the initial expanded value of C<$prompt>. Save the value of lhandler to use as a handler function to call when a complete line of input has been entered. The handler function receives the text of the line as an argument.

=item callback-read-char( )

    Whenever an application determines that keyboard input is available, it should call rl_callback_read_char(), which will read the next character from the current input source. If that character completes the line, rl_callback_read_char will invoke the lhandler function installed by rl_callback_handler_install to process the line. Before calling the lhandler function, the terminal settings are reset to the values they had before calling rl_callback_handler_install. If the lhandler function returns, and the line handler remains installed, the terminal settings are modified for Readline's use again. EOF is indicated by calling lhandler with a NULL line.

=item callback-handler-remove( )

    Restore the terminal to its initial state and remove the line handler. This may be called from within a callback as well as independently. If the handler installed by rl_callback_handler_install does not exit the program, either this function or the function referred to by the value of rl_deprep_term_function should be called before the program exits to reset the terminal settings.

=end Callback

=begin Prompt

These methods manage the readline prompt.

=item set-prompt( Str $prompt ) returns int32

    Make Readline use C<$prompt> for subsequent redisplay. This calls C<rl_expand_prompt()> to expand the prompt and sets C<$rl_prompt> to the result.

=item expand-prompt( Str $prompt ) returns int32

    Expand any special character sequences in C<$prompt> and set up the local Readline prompt redisplay variables. This function is called by C<readline()>. It may also be called to expand the primary prompt if the C<rl_on_new_line_with_prompt()> function or C<$rl-already_prompted> variable is used. It returns the number of visible characters on the last line of the (possibly multi-line) prompt. Applications may indicate that the prompt contains characters that take up no physical screen space when displayed by bracketing a sequence of such characters with the special markers C<RL_PROMPT_START_IGNORE> and C<RL_PROMPT_END_IGNORE> (declared in `readline.h' and exposed in the Readline module as constants.) This may be used to embed terminal-specific escape sequences in prompts.

=end Prompt

=begin Binding

=item bind-key( Str $key, &callback (int32, int32 --> int32) ) returns int32

    rl_bind_key() takes two arguments: C<$key> is the character that you want to bind, and the callback function is called when key is pressed. Binding TAB to C<rl_insert()> makes TAB insert itself. C<rl_bind_key()> returns non-zero if key is not a valid ASCII character code (between 0 and 255).

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_bind_key()> instead.

=item bind-key-in-map( Str $key, &callback (int32, int32 --> int32), Keymap $map ) returns int32

    Bind C<$key> to function in C<$map>. Returns non-zero in the case of an invalid key.

    Editor's note - C<$delimiting-quote> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_bind_key_in_map()> instead.

=item unbind-key( Str $key ) returns Bool

    Bind C<$key> to the null function in the currently active keymap. Returns C<False> in case of error.

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_unbind_key()> instead.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_unbind_key()> function rather than the Perl6 layer.

=item unbind-key-in-map( Str $key, Keymap $map ) returns Bool

    Bind C<$key> to the null function in C<$map>. Returns False in case of error.

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_unbind_key_in_map()> instead.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_unbind_key_in_map()> function rather than the Perl6 layer.

=item bind-key-if-unbound( Str $key, &callback (int32, int32 --> int32) ) returns Bool

    Binds C<$key> to function if it is not already bound in the currently active keymap. Returns False in the case of an invalid key or if key is already bound.

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_bind_key_if_unbound()> instead.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_key_if_unbound()> function rather than the Perl6 layer.

=item bind-key-if-unbound-in-map( Str $key, &callback (int32, int32 --> int32), Keymap $map ) returns Bool

    Binds C<$key> to function if it is not already bound in C<$map>. Returns False in the case of an invalid key or if C<$key> is already bound.

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_bind_key_if_unbound_in_map()> instead.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_keyseq()> function rather than the Perl6 layer.

=item unbind-function-in-map ( &callback (int32, int32 --> int32), Keymap $map ) returns int32

    Unbind all keys that execute function in C<$map>.

=item bind-keyseq( Str $keyseq, &callback (int32, int32 --> int32) ) returns Bool

    Bind the key sequence represented by the string C<$keyseq> to the function function, beginning in the current keymap. This makes new keymaps as necessary. Returns False if C<$keyseq> is invalid.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_keyseq()> function rather than the Perl6 layer.

=item bind-keyseq-in-map( Str $keyseq, &callback (int32, int32 --> int32), Keymap $map ) returns Bool

    Bind the key sequence represented by the string C<$keyseq> to the callback function. This makes new keymaps as necessary. Initial bindings are performed in map. The return value is False if C<$keyseq> is invalid.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_keyseq_in_map()> function rather than the Perl6 layer.

=item bind-keyseq-if-unbound( Str $keyseq, &callback (int32, int32 --> int32) ) returns Bool

    Binds keyseq to function if it is not already bound in the currently active keymap. Returns False in the case of an invalid keyseq or if C<$keyseq> is already bound.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_keyseq_if_unbound()> function rather than the Perl6 layer.

=item bind-keyseq-if-unbound-in-map( Str $str, &callback (int32, int32 --> int32), Keymap $map ) returns Bool

    Binds keyseq to function if it is not already bound in map. Returns non-zero in the case of an invalid keyseq or if keyseq is already bound.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_bind_keyseq_if_unbound_in_map()> function rather than the Perl6 layer.

=item generic-bind( int32 $i, Str $keyseq, Str $t, Keymap $map ) returns int32

    Bind the key sequence represented by the string C<$keyseq> to the arbitrary pointer data. type says what kind of data is pointed to by data; this can be a function (ISFUNC), a macro (ISMACR), or a keymap (ISKMAP). This makes new keymaps as necessary. The initial keymap in which to do bindings is map.

=end Binding

=item add-defun( Str $str, &callback (int32, int32 --> int32), Str $key ) returns int32

    Add name to the list of named functions. Make function be the function that gets called. If C<$key> is not -1, then bind it to function using rl_bind_key().

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_add_defun()> instead.

    Using this function alone is sufficient for most applications. It is the recommended way to add a few functions to the default functions that Readline has built in. If you need to do something other than adding a function to Readline, you may need to use the underlying functions described below.

=item variable-value( Str $variable ) returns Str

    Return a string representing the value of the Readline variable C<$variable>. For boolean variables, this string is either `on' or `off'.

=item variable-bind( Str $variable, Str $value ) returns int32

    Make the Readline variable C<$variable> have value C<$alue>. This behaves as if the readline command `set variable value' had been executed in an inputrc file (see section 1.3.1 Readline Init File Syntax).

=item set-key( Str $str, &callback (int32, int32 --> int32), Keymap $map )

    Equivalent to C<rl-bind-keyseq-in-map()>.

=item macro-bind( Str $keyseq, Str $macro, Keymap $map ) returns int32

    Bind the key sequence C<$keyseq> to invoke the macro C<$macro>. The binding is performed in C<$map>. When C<$keyseq> is invoked, the macro will be inserted into the line. This function is deprecated; use C<rl_generic_bind()> instead.

=item named-function( Str $s ) returns &callback (int32, int32 --> int32)

    Return the function with name name.

=item function-of-keyseq( Str $keyseq, Keymap $map, Pointer[int32] $type ) returns &callback (int32, int32 --> int32)

    Return the function invoked by C<$keyseq> in keymap C<$map>. If C<$map> is Nil, the current keymap is used. If C<$type> is not Nil, the type of the object is returned in the int variable it points to (one of ISFUNC, ISKMAP, or ISMACR).

=item list-funmap-names( )

    Print the names of all bindable Readline functions to rl_outstream.

=item invoking-keyseqs-in-map( Pointer[&callback (int32, int32 --> int32)] $p-cmd, Keymap $map ) returns CArray[Str]

    Return an array of strings representing the key sequences used to invoke function in the keymap C<$map>.

=item invoking-keyseqs( Pointer[&callback (int32, int32 --> int32)] $p-cmd ) returns CArray[Str]

    Return an array of strings representing the key sequences used to invoke function in the current keymap.

=item function-dumper( Bool $readable )

    Print the readline function names and the key sequences currently bound to them to C<$rl_outstream>. If C<$readable> is True, the list is formatted in such a way that it can be made part of an inputrc file and re-read.

    Editor's note - The Perl6 layer translates True values of C<$readable> to non-zero, so if you want to specify a particular int32 value, please use the underlying C<rl_function_dumper()> call.

=item macro-dumper( Bool $readable )

    Print the key sequences bound to macros and their values, using the current keymap, to C<$rl_outstream>. If C<$readable> is True, the list is formatted in such a way that it can be made part of an inputrc file and re-read.

    Editor's note - The Perl6 layer translates True values of C<$readable> to non-zero, so if you want to specify a particular int32 value, please use the underlying C<rl_macro_dumper()> call.

=item variable-dumper( Bool $readable )

    Print the readline variable names and their current values to C<$rl_outstream>. If readable is True, the list is formatted in such a way that it can be made part of an inputrc file and re-read.

    Editor's note - The Perl6 layer translates True values of C<$readable> to non-zero, so if you want to specify a particular int32 value, please use the underlying C<rl_variable_dumper()> call.

=item read-init-file( Str $filename )

    Read keybindings and variable assignments from C<$filename> (see section 1.3 Readline Init File).

=item parse-and-bind( Str $line ) returns int32

    Parse C<$line> as if it had been read from the inputrc file and perform any key bindings and variable assignments found (see section 1.3 Readline Init File).

=item add-funmap-entry( Str $name, &callback (int32, int32 --> int32) ) returns int32

    Add C<$name> to the list of bindable Readline command names, and make function the function to be called when name is invoked.

=item funmap-names( ) returns CArray[Str]

    Return a NULL terminated array of known function names. The array is sorted. The array itself is allocated, but not the strings inside. You should free the array, but not the pointers, using free or rl_free when you are done.

=item push-macro-input( Str $macro )

    Cause C<$macro> to be inserted into the line, as if it had been invoked by a key bound to a macro. Not especially useful; use C<rl_insert_text()> instead.

=item free-undo-list( )

    Free the existing undo list.

=item do-undo( ) returns int32

    Undo the first thing on the undo list. Returns False if there was nothing to undo, True if something was undone.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_do_undo()> function rather than the Perl6 layer.

=item begin-undo-group( ) returns int32

    Begins saving undo information in a group construct. The undo information usually comes from calls to rl_insert_text() and rl_delete_text(), but could be the result of calls to rl_add_undo().

=item end-undo-group( ) returns int32

    Closes the current undo group started with rl_begin_undo_group (). There should be one call to rl_end_undo_group() for each call to rl_begin_undo_group().

=item modifying( int32 $start, int32 $end ) returns int32

    Tell Readline to save the text between C<$start> and C<$end> as a single undo unit. It is assumed that you will subsequently modify that text.

=item redisplay( )

    Change what's displayed on the screen to reflect the current contents of rl_line_buffer.

=item on-new-line( ) returns int32

    Tell the update functions that we have moved onto a new (empty) line, usually after outputting a newline.

=item on-new-line-with-prompt( ) returns int32

    Tell the update functions that we have moved onto a new line, with C<$rl_prompt> already displayed. This could be used by applications that want to output the prompt string themselves, but still need Readline to know the prompt string length for redisplay. It should be used after setting rl_already_prompted.

=item forced-update-display( ) returns int32

    Force the line to be updated and redisplayed, whether or not Readline thinks the screen display is correct.

=item clear-message( ) returns int32

    Clear the message in the echo area. If the prompt was saved with a call to rl_save_prompt before the last call to rl_message, call rl_restore_prompt before calling this function.

=item reset-line-state( ) returns int32

    Reset the display state to a clean state and redisplay the current line starting on a new line.

=item crlf( ) returns int32

    Move the cursor to the start of the next screen line.

=item show-char( Str $c ) returns int32

    Display character c on rl_outstream. If Readline has not been set to display meta characters directly, this will convert meta characters to a meta-prefixed key sequence. This is intended for use by applications which wish to do their own redisplay.

    Editor's note - C<$key> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_show_char()> instead.

=item save-prompt( )

    Save the local Readline prompt display state in preparation for displaying a new message in the message area with rl_message().

=item restore-prompt( )

    Restore the local Readline prompt display state saved by the most recent call to rl_save_prompt. if rl_save_prompt was called to save the prompt before a call to rl_message, this function should be called before the corresponding call to rl_clear_message.

=item replace-line( Str $text, int32 $clear-undo )

    Replace the contents of C<$rl_line_buffer> with C<$text>. The point and mark are preserved, if possible. If C<$clear-undo> is non-zero, the undo list associated with the current line is cleared.

=item insert-text( Str $text ) returns int32

    Insert C<$text> into the line at the current cursor position. Returns the number of characters inserted.

=item delete-text( int32 $start, int32 $end ) returns int32

    Delete the text between C<$start> and C<$end> in the current line. Returns the number of characters deleted.

=item kill-text( int32 $start, int32 $end ) returns int32

    Copy the text between C<$start> and C<$end> in the current line to the kill ring, appending or prepending to the last kill if the last command was a kill command. The text is deleted. If C<$start> is less than C<$end>, the text is appended, otherwise prepended. If the last command was not a kill, a new kill ring slot is used.

=item copy-text( int32 $start, int32 $end ) returns Str

    Return a copy of the text between C<$start> and C<$end> in the current line.

=item prep-terminal( int32 $meta-flag )

    Modify the terminal settings for Readline's use, so readline() can read a single character at a time from the keyboard. The C<$meta-flag> argument should be non-zero if Readline should read eight-bit input.

=item deprep-terminal( )

    Undo the effects of C<rl_prep_terminal()>, leaving the terminal in the state in which it was before the most recent call to C<rl_prep_terminal()>.

=item tty-set-default-bindings( Keymap $map )

    Read the operating system's terminal editing characters (as would be displayed by stty) to their Readline equivalents. The bindings are performed in keymap C<$map>.

=item tty-unset-default-bindings( Keymap $map )

    Reset the bindings manipulated by C<$rl_tty_set_default_bindings> so that the terminal editing characters are bound to C<$rl_insert>. The bindings are performed in keymap C<$map>.

=item reset-terminal( Str $terminal-name ) returns int32

    Reinitialize Readline's idea of the terminal settings using C<$terminal-name> as the terminal type (e.g., vt100). If terminal_name is NULL, the value of the TERM environment variable is used.

=item resize-terminal( )

    Update Readline's internal screen size by reading values from the kernel.

=item set-screen-size( int32 $rows, int32 $cols )

    Set Readline's idea of the terminal size to C<$rows> rows and C<$cols> columns. If either C<$rows> or C<$cols> is less than or equal to 0, Readline's idea of that terminal dimension is unchanged.

If an application does not want to install a SIGWINCH handler, but is still interested in the screen dimensions, Readline's idea of the screen size may be queried.

=item get-screen-size( Pointer[int32] $rows, Pointer[int32] $cols )

    Return Readline's idea of the terminal's size in the variables pointed to by the arguments.

=item reset-screen-size( )

    Cause Readline to reobtain the screen size and recalculate its dimensions.

=item get-termcap( Str $cap ) returns Str

    Retrieve the string value of the termcap capability C<$cap>. Readline fetches the termcap entry for the current terminal name and uses those capabilities to move around the screen line and perform other terminal-specific operations, like erasing a line. Readline does not use all of a terminal's capabilities, and this function will return values for only those capabilities Readline uses.

=item extend-line-buffer( int32 $len )

    Ensure that rl_line_buffer has enough space to hold C<$len> characters, possibly reallocating it if necessary.

=item alphabetic( Str $c ) returns Bool

    Return True if c is an alphabetic character.

    Editor's note - The underlying C function returns non-zero on error, this is mapped onto a Perl6 Bool type. If you want the original behavior, call the underlying C<rl_alphabetic()> function rather than the Perl6 layer.

    Editor's note - C<$c> is an integer in the underlying C API - If you want to use the actual C function call, please call C<rl_alphabetic()> instead.

=item free( Pointer $mem )

    Deallocate the memory pointed to by C<$mem>. C<$mem> must have been allocated by malloc.

=begin Signals

These methods manipulate signal handling for L<Readline>.

=item set-signals( ) returns int32

    Install Readline's signal handler for SIGINT, SIGQUIT, SIGTERM, SIGHUP, SIGALRM, SIGTSTP, SIGTTIN, SIGTTOU, and SIGWINCH, depending on the values of rl_catch_signals and rl_catch_sigwinch.

=item clear-signals( ) returns int32

    Remove all of the Readline signal handlers installed by C<rl_set_signals()>.

=item cleanup-after-signal( )

    This function will reset the state of the terminal to what it was before readline() was called, and remove the Readline signal handlers for all signals, depending on the values of C<$rl-catch-signals> and C<$rl-catch-sigwinch>.

=item reset-after-signal( )

    This will reinitialize the terminal and reinstall any Readline signal handlers, depending on the values of C<$rl_catch_signals> and C<$rl_catch_sigwinch>.

    If an application does not wish Readline to catch SIGWINCH, it may call C<rl_resize_terminal()> or C<rl_set_screen_size()> to force Readline to update its idea of the terminal size when a SIGWINCH is received.

=item free-line-state( )

    This will free any partial state associated with the current input line (undo information, any partial history entry, any partially-entered keyboard macro, and any partially-entered numeric argument). This should be called before C<rl_cleanup_after_signal()>. The Readline signal handler for SIGINT calls this to abort the current input line.

=item echo-signal( int32 $c ) # XXX not in v6

    If an application wishes to install its own signal handlers, but still have readline display characters that generate signals, calling this function with sig set to SIGINT, SIGQUIT, or SIGTSTP will display the character generating that signal.

=end Signals

=item set-paren-blink-timeout( int32 $c ) returns int32

    Set the time interval (in microseconds) that Readline waits when showing a balancing character when blink-matching-paren has been enabled.

=item complete-internal( int32 $what-to-do ) returns int32

    Complete the word at or before point. C<$what-to-do> says what to do with the completion. A value of `?' means list the possible completions. `TAB' means do standard completion. `*' means insert all of the possible completions. `!' means to display all of the possible completions, if there is more than one, as well as performing partial completion. `@' is similar to `!', but possible completions are not listed if the possible completions share a common prefix.

=item username-completion-function ( Str $text, int32 $i ) returns Str # XXX doesn't exist?

    A completion generator for usernames. C<$text> contains a partial username preceded by a random character (usually `~'). As with all completion generators, state is zero on the first call and non-zero for subsequent calls.

=item filename-completion-function ( Str $text, int32 $i ) returns Str # XXX Doesn't exist?

    A generator function for filename completion in the general case. C<$text> is a partial filename. The Bash source is a useful reference for writing application-specific completion functions (the Bash completion functions call this and other Readline functions).

=item completion-mode( Pointer[&callback (int32, int32 --> int32)] $cfunc ) returns int32

    Returns the appropriate value to pass to C<rl_complete_internal()> depending on whether C<$cfunc> was called twice in succession and the values of the show-all-if-ambiguous and show-all-if-unmodified variables. Application-specific completion functions may use this function to present the same interface as rl_complete().

=item save-state( readline_state $sp ) returns int32

    Save a snapshot of Readline's internal state to C<$sp>. The contents of the readline_state structure are documented in `readline.h'. The caller is responsible for allocating the structure.

=item tilde-expand( Str $str ) returns Str

    Return a new string which is the result of tilde-expanding C<$str>.

=item tilde-expand-word( Str $filename ) returns Str

    Do the work of tilde expansion on C<$filename>.  C<$filename> starts with a tilde.  If there is no expansion, call C<$tilde_expansion_failure_hook>.

=item tilde-find-word( Str $word, int32 $offset, Pointer[int32] $p-end-offset ) returns Str

    Find the portion of the string beginning with ~ that should be expanded.

=item restore-state( readline_state $sp ) returns int32

    Restore Readline's internal state to that stored in C<$sp>, which must have been saved by a call to C<rl_save_state()>. The contents of the readline_state structure are documented in `readline.h'. The caller is responsible for freeing the structure.

=end METHODS

=end pod

class Readline:ver<0.1.5> {

  sub LIBREADLINE {
    my $library = 'readline';
    my $library-match = rx/:i libreadline\.so\.(\d+) $/;
    my $version = v7;

    # Collect library paths from arbitrary OSen to search.
    #
    my constant LIBRARY-PATHS = (
      '/lib/x86_64-linux-gnu', # Author's VM
      '/usr/local/lib',        # Generic path
      '/usr/lib64',            # Slackware 14 among others
      '/usr/lib',              # Generic path
      '/lib'                   # even more generic.
    );
    my @library-path = grep { .IO.e }, LIBRARY-PATHS;

    given $*VM.osname {
      when 'openbsd' {
        $library = 'ereadline';
        $library-match = rx/:i libereadline\.so\.(\d+) $/;
        $version = v2.0;
        my sub tgetnum(Str --> int32) is native('ncurses') { * }
        tgetnum('');
      }
      when 'darwin' {
        # needs homebrew installed version of readline
        # macOS ships with incompatible libedit
        $library-match = rx/:i libreadline\.(\d+)\.dylib $/;
        # set version to v0.0 so we can check if it was found
        $version = v0.0;
        # homebrew directory
        @library-path = ('/usr/local/opt/readline/lib')
    }
    }

    # Search each of the LIBRARY-PATHS paths for libreadline.
    #
    for @library-path -> $path {
      # Filter out everything but libreadline.{so,dylib}
      # Sort it so the last entry is the latest
      #
      my @dir = sort dir( $path, :test( $library-match ) );
      next unless @dir;

      @dir[*-1] ~~ $library-match;
      $version = Version.new( ( $0 ) );
      last;
    }

    given $*DISTRO.name {
      when 'slackware' {
        if $version ~~ v6 {
          my sub tgetnum(Str --> int32) is native('ncurses') { * }
          tgetnum('');
        }
      }
      when rx/"macos" | "darwin"/ {
        # die if we didn't find sometging
        # currently only supports the location from Homebrew
        if $version ~~ v0.0 {
          die('On macOS Perl6::Readline requires installing Readline via Homebrew');
        }
      
        # if we ever support another location, we will need to test where the file is
        return ("@library-path[0]/libreadline.$version.dylib");
      }
    }

    ( $library, $version )
  }

  # Embedded typedefs here
  #
#  my class histdata_t is repr('CPointer') { }; # typedef char *histdata_t;
  my class time_t is repr('CPointer') { }; # XXX probably already a native type.
  my class Keymap is repr('CPointer') { }; # typedef KEYMAP_ENTRY *Keymap;
  # typedef void rl_vcpfunc_t (char *);

  #my class rl_command_func_t is repr('CPointer') { }; #typedef int rl_command_func_t (int, int);
  my class rl_compentry_func_t is repr('CPointer') { }; #typedef char *rl_compentry_func_t (const char *, int);

  constant meta_character_threshold = 0x07f; # Larger than this is Meta.
  constant meta_character_bit       = 0x080; # x0000000, must be on.
  constant largest_char             = 255;   # Largest character value.

  sub META_CHAR( $c ) {
    ord( $c ) > meta_character_threshold && ord( $c ) <= largest_char
  }

  sub META( $c ) {
    ord( $c ) | meta_character_bit
  }

  sub UNMETA( $c ) {
    ord( $c ) & ~meta_character_bit
  }

  ############################################################################
  #
  # history.h -- the names of functions that you can call in history.
  #

  # The structure used to store a history entry.
  #
  my class HIST_ENTRY is repr('CStruct') {
    has Str $.line;        # char *line;
    has Str $.timestamp;   # char *timestamp;
#    has histdata_t $.data; # histdata_t data;
    has Str $.data;        # histdata_t is really char*
  }

  # Size of the history-library-managed space in history entry HS.
  #
  sub HISTENT_BYTES( $hs ) {
    $hs.line.length + $hs.timestamp.length
  }

  # A structure used to pass the current state of the history stuff around.
  #
  my class HISTORY_STATE is repr('CStruct') {
    has Pointer $.entries; # Pointer to an array of HIST_ENTRY types.
    has int     $.offset;  # The location pointer within this array.
    has int     $.length;  # Number of elements within this array.
    has int     $.size;    # Number of slots allocated to this array.
    has int     $.flags;
  }

  # Flag values for the `flags' member of HISTORY_STATE.
  #
  constant HS_STIFLED = 0x01;

  # Initialization and state management.
  #
  # Begin a session in which the history functions might be used.  This
  # just initializes the interactive variables.
  #
  sub using_history( )
    is native( LIBREADLINE ) { * }
  method using-history( ) {
    using_history() }

  # Return the current HISTORY_STATE of the history.
  #
  sub history_get_history_state( )
    returns HISTORY_STATE
    is native( LIBREADLINE ) { * }
  method history-get-history-state( )
    returns HISTORY_STATE {
    history_get_history_state() }

  # Set the state of the current history array to STATE.
  #
  sub history_set_history_state( HISTORY_STATE )
    is native( LIBREADLINE ) { * }
  method history-set-history-state( HISTORY_STATE $state ) {
    history_set_history_state( $state ) }

  # Manage the history list.
  #
  # Place STRING at the end of the history list.
  # The associated data field (if any) is set to NULL.
  #
  sub add_history( Str ) is export
    is native( LIBREADLINE ) { * }
  method add-history( Str $history ) {
    add_history( $history ) }

  # Change the timestamp associated with the most recent history entry to
  # STRING.
  #
  sub add_history_time( Str )
    is native( LIBREADLINE ) { * }
  method add-history-time( Str $timestamp ) {
    add_history_time( $timestamp ) }

  # A reasonably useless function, only here for completeness.  WHICH
  # is the magic number that tells us which element to delete.  The
  # elements are numbered from 0.
  #
  sub remove_history( int32 )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
  method remove-history( int32 $which )
    returns HIST_ENTRY {
    remove_history( $which ) }

  # Free the history entry H and return any application-specific data
  # associated with it.
  #
  sub free_history_entry( HIST_ENTRY )
#    returns histdata_t
    returns Str
    is native( LIBREADLINE ) { * }
  method free-history-entry( HIST_ENTRY $entry )
#    returns histdata_t {
    returns Str {
    free_history_entry( $entry ) }

#  sub replace_history_entry( int32, Str, histdata_t )
  sub replace_history_entry( int32, Str, Str )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
#  method replace-history-entry( int32 $which, Str $line, histdata_t $data )
  method replace-history-entry( int32 $which, Str $line, Str $data )
    returns HIST_ENTRY {
      replace_history_entry( $which, $line, $data ) }

  sub clear_history( )
    is native( LIBREADLINE ) { * }
  method clear-history( ) {
    clear_history() }

  sub stifle_history( int32 )
    is native( LIBREADLINE ) { * }
  method stifle-history( int32 $max ) {
    stifle_history( $max ) }

  sub unstifle_history( )
    is native( LIBREADLINE ) { * }
  method unstifle-history( ) {
    unstifle_history() }

  sub history_is_stifled( )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-is-stifled( )
    returns Bool {
    history_is_stifled() ?? True !! False }

  # Information about the history list.
  #
  sub history_list( )
    returns CArray[HIST_ENTRY]
    is native( LIBREADLINE ) { * }
  method history-list( )
    returns CArray[HIST_ENTRY] {
    history_list() }

  sub where_history( )
    returns int32
    is native( LIBREADLINE ) { * }
  method where-history( )
    returns int32 {
    where_history() }

  sub current_history( int32 )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
  method current-history( int32 $which )
    returns HIST_ENTRY {
    current_history( $which ) }

  sub history_get( int32 )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
  method history-get( int32 $which )
    returns HIST_ENTRY {
    history_get( $which ) }

  sub history_get_time( HIST_ENTRY )
    returns time_t
    is native( LIBREADLINE ) { * }
  method history-get-time( HIST_ENTRY $h )
    returns time_t {
    history_get_time( $h ) }

  sub history_total_bytes( )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-total-bytes( )
    returns int32 {
    history_total_bytes( ) }

  # Moving around the history list.
  #
  sub history_set_pos( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-set-pos( int32 $pos )
    returns int32 {
    history_set_pos( $pos ) }

  sub previous_history( )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
  method previous-history( )
    returns HIST_ENTRY {
    previous_history( ) }

  sub next_history( )
    returns HIST_ENTRY
    is native( LIBREADLINE ) { * }
  method next-history( )
    returns HIST_ENTRY {
    next_history( ) }

  # Searching the history list.
  #
  sub history_search( Str, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-search( Str $text, int32 $pos )
    returns int32 {
    history_search( $text, $pos ) }

  sub history_search_prefix( Str, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-search-prefix( Str $text, int32 $pos )
    returns int32 {
    history_search_prefix( $text, $pos ) }

  sub history_search_pos( Str, int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-search-pos( Str $text, int32 $pos, int32 $dir )
    returns int32 {
    history_search_pos( $text, $pos, $dir ) }

  # Managing the history file.
  #
  sub read_history( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method read-history( Str $text )
    returns int32 {
    my $rv = read_history( $text );
    $rv == 0 ?? True !! $rv }

  sub read_history_range( Str, int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method read-history-range( Str $text, int32 $from, int32 $to )
    returns int32 {
    read_history_range( $text, $from, $to ) }

  sub write_history( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method write-history( Str $filename )
    returns int32 {
    my $rv = write_history( $filename );
    $rv == 0 ?? True !! $rv }

  sub append_history( int32, Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method append-history( int32 $offset, Str $filename )
    returns int32 {
    append_history( $offset, $filename ) }

  sub history_truncate_file( Str, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-truncate-file( Str $filename, int32 $nLines )
    returns int32 {
    my $rv = history_truncate_file( $filename, $nLines );
    $rv == 0 ?? True !! $rv }

  # History expansion.
  #
  sub history_expand( Str, Pointer[Str] )
    returns int32
    is native( LIBREADLINE ) { * }
  method history-expand( Str $string, Pointer[Str] $output )
    returns int32 {
    history_expand( $string, $output ) }

  sub history_arg_extract( int32, int32, Str )
    returns Str
    is native( LIBREADLINE ) { * }
  method history-arg-extract( int32 $first, int32 $last, Str $string )
    returns Str {
    history_arg_extract( $first, $last, $string ) }

  sub get_history_event( Str, Pointer[int32], int32 )
    returns Str
    is native( LIBREADLINE ) { * }
  method get-history-event( Str $string, Pointer[int32] $index, Str $delimiting-quote )
    returns Str {
    get_history_event( $string, $index, ord( $delimiting-quote.substr(0,1) ) ) }


  sub history_tokenize( Str )
    returns CArray[Str]
    is native( LIBREADLINE ) { * }
  method history-tokenize( Str $string )
    returns CArray[Str] {
    history_tokenize( $string ) }

  # Exported history variables.
  #extern int history_base;
  #extern int history_length;
  #extern int history_max_entries;
  #extern char history_expansion_char;
  #extern char history_subst_char;
  #extern char *history_word_delimiters;
  #extern char history_comment_char;
  #extern char *history_no_expand_chars;
  #extern char *history_search_delimiter_chars;
  #extern int history_quotes_inhibit_expansion;

  #extern int history_write_timestamps;

  # Backwards compatibility 
  #
  #extern int max_input_history;

  # If set, this function is called to decide whether or not a particular
  # history expansion should be treated as a special case for the calling
  # application and not expanded.
  #
  #extern rl_linebuf_func_t *history_inhibit_expansion_function;

  #############################################################################
  #
  # keymaps.h -- Manipulation of readline keymaps.
  #
  # A keymap contains one entry for each key in the ASCII set.
  # Each entry consists of a type and a pointer.
  # FUNCTION is the address of a function to run, or the
  # address of a keymap to indirect through.
  # TYPE says which kind of thing FUNCTION is.
  #

  my class KEYMAP_ENTRY is repr('CStruct') {
    has byte              $.type;     # char type;
#    has rl_command_func_t $.function; # rl_command_func_t *function # XXX
  }

  # This must be large enough to hold bindings for all of the characters
  # in a desired character set (e.g, 128 for ASCII, 256 for ISO Latin-x,
  # and so on) plus one for subsequence matching.
  #
  constant KEYMAP_SIZE = 257;
  constant ANYOTHERKEY = KEYMAP_SIZE - 1;

  #typedef KEYMAP_ENTRY KEYMAP_ENTRY_ARRAY[KEYMAP_SIZE];
  #
  # The values that TYPE can have in a keymap entry.
  #
  constant ISFUNC = 0;
  constant ISKMAP = 1;
  constant ISMACR = 2;

  #extern KEYMAP_ENTRY_ARRAY emacs_standard_keymap, emacs_meta_keymap;
  #extern KEYMAP_ENTRY emacs_ctlx_keymap;
  #extern KEYMAP_ENTRY_ARRAY vi_insertion_keymap, vi_movement_keymap;

  sub rl_make_bare_keymap( )
    returns Keymap
    is native( LIBREADLINE ) { * }
  method make-bare-keymap( )
    returns Keymap {
    rl_make_bare_keymap( ) }

  sub rl_copy_keymap( Keymap )
    returns Keymap
    is native( LIBREADLINE ) { * }
  method copy-keymap( Keymap $map )
    returns Keymap {
    rl_copy_keymap( $map ) }

  sub rl_make_keymap( )
    returns Keymap
    is native( LIBREADLINE ) { * }
  method make-keymap( )
    returns Keymap {
    rl_make_keymap( ) }

  sub rl_discard_keymap( Keymap )
    is native( LIBREADLINE ) { * }
  method discard-keymap( Keymap $map ) {
    rl_discard_keymap( $map ) }

  sub rl_free_keymap( Keymap )
    is native( LIBREADLINE ) { * }
  method free-keymap( Keymap $map ) {
    rl_free_keymap( $map ) }

  # These functions actually appear in bind.c
  #
  sub rl_get_keymap_by_name( Str )
    returns Keymap
    is native( LIBREADLINE ) { * }
  method get-keymap-by-name( Str $name )
    returns Keymap {
    rl_get_keymap_by_name( $name ) }

  sub rl_get_keymap( )
    returns Keymap
    is native( LIBREADLINE ) { * }
  method get-keymap( )
    returns Keymap {
    rl_get_keymap( ) }

  sub rl_get_keymap_name( Keymap )
    returns Str
    is native( LIBREADLINE ) { * }
  method get-keymap-name( Keymap $map )
    returns Str {
    rl_get_keymap_name( $map ) }

  sub rl_set_keymap( Keymap )
    is native( LIBREADLINE ) { * }
  method set-keymap( Keymap $map ) {
    rl_set_keymap( $map ) }

  #############################################################################
  #
  # Readline.h -- the names of functions callable from within readline.
  #
  # Readline data structures.
  #
  # Maintaining the state of undo.  We remember individual deletes and inserts
  # on a chain of things to do.
  #
  # The actions that undo knows how to undo.  Notice that UNDO_DELETE means
  # to insert some text, and UNDO_INSERT means to delete some text.   I.e.,
  # the code tells undo what to undo, not how to undo it.
  #
  #enum undo_code { UNDO_DELETE, UNDO_INSERT, UNDO_BEGIN, UNDO_END };

  constant UNDO_DELETE = 0;
  constant UNDO_INSERT = 1;
  constant UNDO_BEGIN  = 2;
  constant UNDO_END    = 3;

  # What an element of THE_UNDO_LIST looks like.
  #
  my class UNDO_LIST is repr('CStruct') {
    has UNDO_LIST $.next; # struct undo_list *next;
    has int $.start;      # int start; # Where the change took place.
    has int $.end;        # int end;
    has Str $.text;       # char *text; # The text to insert, if undoing a delete
    has byte $.what;      # enum undo_code what; # Delete, Insert, Begin, End.
  }

  # The current undo list for RL_LINE_BUFFER.
  #
  #extern UNDO_LIST *rl_undo_list;

  # The data structure for mapping textual names to code addresses.
  #
  my class FUNMAP is repr('CStruct') {
    has Str     $.name;     # const char *name;
#    has Pointer $.function; # rl_command_func_t *function; # XXX
  }

  #extern FUNMAP **funmap;

  # Bindable commands for numeric arguments.
  #
  # These should only be passed as callbacks, I believe.
  #
  sub rl_digit_argument( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_universal_argument( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for moving the cursor.
  #
  sub rl_forward_byte( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_forward_char( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_forward( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_byte( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_char( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_beg_of_line( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_end_of_line( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_forward_word( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_word( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_refresh_line( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_clear_screen( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_skip_csi_sequence( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_arrow_keys( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for inserting and deleting text.
  #
  sub rl_insert( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_quoted_insert( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_tab_insert( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_newline( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_do_lowercase_version( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_rubout( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_delete( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_rubout_or_delete( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_delete_horizontal_space( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_delete_or_show_completions( int32, int32 ) returns int32
    is native( LIBREADLINE ) { * }
  sub rl_insert_comment( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for changing case.
  #
  sub rl_upcase_word( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_downcase_word( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_capitalize_word( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for transposing characters and words.
  #
  sub rl_transpose_words( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_transpose_chars( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for searching within a line.
  #
  sub rl_char_search( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_char_search( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for readline's interface to the command history.
  #
  sub rl_beginning_of_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_end_of_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_get_next_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_get_previous_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for managing the mark and region.
  #
  sub rl_set_mark ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_exchange_point_and_mark ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands to set the editing mode (emacs or vi).
  #
  sub rl_vi_editing_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_emacs_editing_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands to change the insert mode (insert or overwrite)
  #
  sub rl_overwrite_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for managing key bindings.
  #
  sub rl_re_read_init_file ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_dump_functions ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_dump_macros ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_dump_variables ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for word completion.
  #
  sub rl_complete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_possible_completions ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_insert_completions ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_old_menu_complete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_menu_complete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_menu_complete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for killing and yanking text, and managing the kill ring.
  #
  sub rl_kill_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_kill_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_kill_line ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_backward_kill_line ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_kill_full_line ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_unix_word_rubout ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_unix_filename_rubout ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_unix_line_discard ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_copy_region_to_kill ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_kill_region ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_copy_forward_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_copy_backward_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_yank ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_yank_pop ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_yank_nth_arg ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_yank_last_arg ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_paste_from_clipboard ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for incremental searching.
  #
  sub rl_reverse_search_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_forward_search_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable keyboard macro commands.
  #
  sub rl_start_kbd_macro ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_end_kbd_macro ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_call_last_kbd_macro ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_print_last_kbd_macro ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  #
  # Bindable undo commands.
  #
  sub rl_revert_line ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_undo_command ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable tilde expansion commands.
  #
  sub rl_tilde_expand ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable terminal control commands.
  #
  sub rl_restart_output ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_stop_output ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Miscellaneous bindable commands.
  #
  sub rl_abort ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_tty_status ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Bindable commands for incremental and non-incremental history searching.
  #
  sub rl_history_search_forward ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_history_search_backward ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_history_substr_search_forward ( int32, int32 ) returns int32
    is native( LIBREADLINE ) { * }
  sub rl_history_substr_search_backward ( int32, int32 ) returns int32
    is native( LIBREADLINE ) { * }
  sub rl_noninc_forward_search ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_noninc_reverse_search ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_noninc_forward_search_again ( int32, int32 ) returns int32
    is native( LIBREADLINE ) { * }
  sub rl_noninc_reverse_search_again ( int32, int32 ) returns int32
    is native( LIBREADLINE ) { * }

  # Bindable command used when inserting a matching close character.
  #
  sub rl_insert_close ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # Not available unless READLINE_CALLBACKS is defined.
  #

 sub rl_callback_handler_install( Str, &callback (Str) ) is export
   is native( LIBREADLINE ) { * }
#  method callback-handler-install( Str $s, &callback (Str) ) {
#    rl_callback_handler_install( $s, $cb ) }

  sub rl_callback_read_char( ) is export
    is native( LIBREADLINE ) { * }
  method callback-read-char( ) {
    rl_callback_read_char( ) }
 
  sub rl_callback_handler_remove( ) is export
    is native( LIBREADLINE ) { * }
  method callback-handler-remove( ) {
    rl_callback_handler_remove( ) }

  # Things for vi mode. Not available unless readline is compiled -DVI_MODE.
  #
  # VI-mode bindable commands.
  #
  sub rl_vi_redo ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_undo ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_yank_arg ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_fetch_history ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_search_again ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_search ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_complete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_tilde_expand ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_prev_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_next_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_end_word ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_insert_beg ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_append_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_append_eol ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_eof_maybe ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_insertion_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_insert_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_movement_mode ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_arg_digit ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_change_case ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_put ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_column ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_delete_to ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_change_to ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_yank_to ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_rubout ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_delete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_back_to_indent ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_first_print ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_char_search ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_match ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_change_char ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_subst ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_overstrike ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_overstrike_delete ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_replace ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_set_mark ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_goto_mark ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # VI-mode utility functions.
  #
  sub rl_vi_check( ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_domove( int32, Pointer[int32] ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_bracktype( int32 ) returns int32 is native( LIBREADLINE ) { * }

  sub rl_vi_start_inserting( int32, int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  # VI-mode pseudo-bindable commands, used as utility functions.
  #
  sub rl_vi_fWord ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_bWord ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_eWord ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_fword ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_bword ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }
  sub rl_vi_eword ( int32, int32 ) returns int32 is native( LIBREADLINE ) { * }

  ###################################################################
  #								    #
  #			Well Published Functions		    #
  #								    #
  ###################################################################
  #
  # Readline functions.
  #
  sub readline( Str )
    is export
    returns Str
    is native( LIBREADLINE ) { * }
  method readline( Str $prompt )
    returns Str {
    readline( $prompt ) }

  sub rl_set_prompt( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method set-prompt( Str $prompt )
    returns int32 {
    rl_set_prompt( $prompt ) }

  sub rl_expand_prompt( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method expand-prompt( Str $prompt )
    returns int32 {
    rl_expand_prompt( $prompt ) }

  sub rl_initialize( )
    returns int32
    is native( LIBREADLINE ) { * }
  method initialize( )
    returns int32 {
    rl_initialize( ) }

  # Utility functions to bind keys to readline commands.
  #
  sub rl_bind_key( int32, &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-key( Str $key, $cb )
    returns int32 {
    rl_bind_key( ord( $key.substr(0,1) ), $cb ) }

  sub rl_bind_key_in_map( int32, &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-key-in-map( Str $key, $cb, Keymap $map )
    returns int32 {
    rl_bind_key_in_map( ord( $key.substr(0,1) ), $cb, $map ) }

  sub rl_unbind_key( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method unbind-key( Str $key )
    returns Bool {
    rl_unbind_key( ord( $key.substr(0,1) ) ) != 0 ?? False !! True }

  sub rl_unbind_key_in_map( int32, Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method unbind-key-in-map( Str $key, Keymap $map )
    returns Bool {
    rl_unbind_key_in_map( ord( $key.substr(0,1) ), $map ) != 0 ?? False !! True }

  sub rl_bind_key_if_unbound( int32, &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-key-if-unbound( Str $key, $cb )
    returns int32 {
    rl_bind_key_if_unbound( ord( $key.substr(0,1) ), $cb ) }

  sub rl_bind_key_if_unbound_in_map( int32, &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-key-if-unbound-in-map
    ( Str $key, $cb, Keymap $map )
    returns Bool {
      rl_bind_key_if_unbound_in_map( ord( $key.substr(0,1) ), $cb, $map ) != 0 ?? False !! True }

  sub rl_unbind_function_in_map( &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method unbind-function-in-map ( $cb, Keymap $map )
    returns int32 {
      rl_unbind_function_in_map( $cb, $map ) }

  sub rl_bind_keyseq( Str, &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-keyseq( Str $str, $cb )
    returns Bool {
      rl_bind_keyseq( $str, $cb ) != 0 ?? False !! True }

  sub rl_bind_keyseq_in_map( Str, &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-keyseq-in-map( Str $str, $cb, Keymap $map )
    returns Bool {
      rl_bind_keyseq_in_map( $str, $cb, $map ) != 0 ?? False !! True }

  sub rl_bind_keyseq_if_unbound( Str, &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-keyseq-if-unbound( Str $str, $cb )
   returns Bool {
    rl_bind_keyseq_if_unbound( $str, $cb ) != 0 ?? False !! True }

  sub rl_bind_keyseq_if_unbound_in_map
    ( Str, &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method bind-keyseq-if-unbound-in-map
    ( Str $str, $cb, Keymap $map )
    returns Bool {
      rl_bind_keyseq_if_unbound_in_map( $str, $cb, $map )
        != 0 ?? False !! True }

  sub rl_generic_bind( int32, Str, Str, Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method generic-bind( int32 $i, Str $s, Str $t, Keymap $map )
    returns int32 {
    rl_generic_bind( $i, $s, $t, $map ) }

  sub rl_add_defun( Str, &callback (int32, int32 --> int32), int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method add-defun( Str $str, $cb, Str $key )
    returns int32 {
    rl_add_defun( $str, $cb, ord( $key.substr(0,1) ) ) }

  sub rl_variable_value( Str )
    returns Str
    is native( LIBREADLINE ) { * }
  method variable-value( Str $s )
    returns Str {
    rl_variable_value( $s ) }

  sub rl_variable_bind( Str, Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method variable-bind( Str $s, Str $t )
    returns int32 {
    rl_variable_bind( $s, $t ) }

  # Backwards compatibility, use rl_bind_keyseq_in_map instead.
  #
  sub rl_set_key( Str, &callback (int32, int32 --> int32), Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method set-key( Str $str, $cb, Keymap $map )
    returns int32 {
      rl_set_key( $str, $cb, $map ) }

  # Backwards compatibility, use rl_generic_bind instead.
  #
  sub rl_macro_bind( Str, Str, Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
  method macro-bind( Str $str, Str $b, Keymap $map )
    returns int32 {
    rl_macro_bind( $str, $b, $map ) }

  sub rl_named_function( Str, Str, Keymap )
    returns int32
    is native( LIBREADLINE ) { * }
#  method named-function( Str $str ) {
#    returns &callback (int32, int32 --> int32) {
#    rl_macro_bind( $str, $b, $map ) }

  sub rl_translate_keyseq( Str, Str, Pointer[int32] )
    returns int32
    is native( LIBREADLINE ) { * }
  method translate-keyseq( Str $str, Str $b, Pointer[int32] $k )
    returns int32 {
    rl_translate_keyseq( $str, $b, $k ) }

  sub rl_untranslate_keyseq( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method untranslate-keyseq( int32 $i )
    returns int32 {
    rl_untranslate_keyseq( $i ) }

# XXX Not sure how to return callback type.
#
#  sub rl_named_function( Str )
#    returns &callback (int32, int32 --> int32)
#    is native( LIBREADLINE ) { * }
#  method named-function( Str $s )
#    returns rl_command_func_t {
#    rl_named_function( $s ) }

# XXX Not sure how to return callback type.
#
#  sub rl_function_of_keyseq( Str, Keymap, Pointer[int32] )
#    returns &callback (int32, int32 --> int32)
#    is native( LIBREADLINE ) { * }
#  method function-of-keyseq( Str $s, Keymap $map, Pointer[int32] $p )
#    returns rl_command_func_t {
#      rl_function_of_keyseq( $s, $map, $p ) }

  sub rl_list_funmap_names( )
    is native( LIBREADLINE ) { * }
  method list-funmap-names( ) {
    rl_list_funmap_names( ) }

  sub rl_invoking_keyseqs_in_map( &callback (int32, int32 --> int32), Keymap )
    returns CArray[Str]
    is native( LIBREADLINE ) { * }
  method invoking-keyseqs-in-map( $cb, Keymap $map )
    returns CArray[Str] {
      rl_invoking_keyseqs_in_map( $cb, $map ) }

  sub rl_invoking_keyseqs( &callback (int32, int32 --> int32) )
    returns CArray[Str]
    is native( LIBREADLINE ) { * }
  method invoking-keyseqs( $cb )
    returns CArray[Str] {
    rl_invoking_keyseqs( $cb ) }

  sub rl_function_dumper( int32 )
    is native( LIBREADLINE ) { * }
  method function-dumper( Bool $readable ) {
    rl_function_dumper( $readable ?? 1 !! 0 ) }

  sub rl_macro_dumper( int32 )
    is native( LIBREADLINE ) { * }
  method macro-dumper( Bool $readable ) {
    rl_macro_dumper( $readable ?? 1 !! 0 ) }

  sub rl_variable_dumper( int32 )
    is native( LIBREADLINE ) { * }
  method variable-dumper( Bool $readable ) {
    rl_variable_dumper( $readable ?? 1 !! 0 ) }

  sub rl_read_init_file( Str )
    is native( LIBREADLINE ) { * }
  method read-init-file( Str $line ) {
    rl_read_init_file( $line ) }

  sub rl_parse_and_bind( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method parse-and-bind( Str $line )
    returns int32 {
    rl_parse_and_bind( $line ) }

  # Functions for manipulating the funmap, which maps command names
  # to functions.
  #
  sub rl_add_funmap_entry( Str, &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method add-funmap-entry( Str $name, $cb ) # XXX Type this properly
    returns int32 {
    rl_add_funmap_entry( $name, $cb ) }

  sub rl_funmap_names( )
    returns CArray[Str]
    is native( LIBREADLINE ) { * }
  method funmap-names( )
    returns CArray[Str] {
    rl_funmap_names( ) }

  # Utility functions for managing keyboard macros.
  #
  sub rl_push_macro_input( Str )
    is native( LIBREADLINE ) { * }
  method push-macro-input( Str $macro ) {
    rl_push_macro_input( $macro ) }

  # Functions for undoing, from undo.c
  #
  sub rl_add_undo( int32, int32, int32, Str ) # XXX first arg is undo_code
    is native( LIBREADLINE ) { * }
  method add-undo( int32 $code, int32 $a, int32 $b, Str $mark ) {
    rl_add_undo( $code, $a, $b, $mark ) }

  sub rl_free_undo_list( )
    is native( LIBREADLINE ) { * }
  method free-undo-list( ) {
    rl_free_undo_list( ) }

  sub rl_do_undo( )
    returns int32
    is native( LIBREADLINE ) { * }
  method do-undo( )
    returns Bool {
    rl_do_undo( ) == 0 ?? False !! True }

  sub rl_begin_undo_group( )
    returns int32
    is native( LIBREADLINE ) { * }
  method begin-undo-group( )
    returns int32 {
    rl_begin_undo_group( ) }

  sub rl_end_undo_group( )
    returns int32
    is native( LIBREADLINE ) { * }
  method end-undo-group( )
    returns int32 {
    rl_end_undo_group( ) }

  sub rl_modifying( int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method modifying( int32 $start, int32 $end )
    returns int32 {
    rl_modifying( $start, $end ) }

  # Functions for redisplay.
  #
  sub rl_redisplay( )
    is native( LIBREADLINE ) { * }
  method redisplay( ) {
    rl_redisplay( ) }

  sub rl_on_new_line( )
    returns int32
    is native( LIBREADLINE ) { * }
  method on-new-line( )
    returns int32 {
    rl_on_new_line( ) }

  sub rl_on_new_line_with_prompt( )
    returns int32
    is native( LIBREADLINE ) { * }
  method on-new-line-with-prompt( )
    returns int32 {
    rl_on_new_line_with_prompt( ) }

  sub rl_forced_update_display( )
    returns int32
    is native( LIBREADLINE ) { * }
  method forced-update-display( )
    returns int32 {
    rl_forced_update_display( ) }

  sub rl_clear_message( )
    returns int32
    is native( LIBREADLINE ) { * }
  method clear-message( )
    returns int32 {
    rl_clear_message( ) }

  sub rl_reset_line_state( )
    returns int32
    is native( LIBREADLINE ) { * }
  method reset-line-state( )
    returns int32 {
    rl_reset_line_state( ) }

  sub rl_crlf( )
    returns int32
    is native( LIBREADLINE ) { * }
  method crlf( )
    returns int32 {
    rl_crlf( ) }

  #extern int rl_message (const char *, ...)  __rl_attribute__((__format__ (printf, 1, 2)); # XXX

  sub rl_show_char( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method show-char( Str $c )
    returns int32 {
    rl_show_char( ord( $c.substr(0,1) ) ) }

  # Undocumented in texinfo manual.
  #
  sub rl_character_len( int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method character-len( int32 $c, int32 $d )
    returns int32 {
    rl_character_len( $c, $d ) }

  # Save and restore internal prompt redisplay information.
  #
  sub rl_save_prompt( )
    is native( LIBREADLINE ) { * }
  method save-prompt( ) {
    rl_save_prompt( ) }

  sub rl_restore_prompt( )
    is native( LIBREADLINE ) { * }
  method restore-prompt( ) {
    rl_restore_prompt( ) }

  # Modifying text.
  #
  sub rl_replace_line( Str, int32 )
    is native( LIBREADLINE ) { * }
  method replace-line( Str $text, int32 $clear-undo ) {
    rl_replace_line( $text, $clear-undo ) }

  sub rl_insert_text( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method insert-text( Str $text )
    returns int32 {
    rl_insert_text( $text ) }

  sub rl_delete_text( int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method delete-text( int32 $start, int32 $end )
    returns int32 {
    rl_delete_text( $start, $end ) }

  sub rl_kill_text( int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method kill-text( int32 $start, int32 $end )
    returns int32 {
    rl_kill_text( $start, $end ) }

  sub rl_copy_text( int32, int32 )
    returns Str
    is native( LIBREADLINE ) { * }
  method copy-text( int32 $start, int32 $end )
    returns Str {
    rl_copy_text( $start, $end ) }

  # Terminal and tty mode management.
  #
  sub rl_prep_terminal( int32 )
    is native( LIBREADLINE ) { * }
  method prep-terminal( int32 $meta-flag ) {
    rl_prep_terminal( $meta-flag ) }

  sub rl_deprep_terminal( )
    is native( LIBREADLINE ) { * }
  method deprep-terminal( ) {
    rl_deprep_terminal( ) }

  sub rl_tty_set_default_bindings( Keymap )
    is native( LIBREADLINE ) { * }
  method tty-set-default-bindings( Keymap $map ) {
    rl_tty_set_default_bindings ( $map ) }

  sub rl_tty_unset_default_bindings ( Keymap )
    is native( LIBREADLINE ) { * }
  method tty-unset-default-bindings( Keymap $map ) {
    rl_tty_unset_default_bindings ( $map ) }

  sub rl_reset_terminal( Str )
    returns int32
    is native( LIBREADLINE ) { * }
  method reset-terminal( Str $terminal-name )
    returns int32 {
    rl_reset_terminal( $terminal-name ) }

  sub rl_resize_terminal( )
    is native( LIBREADLINE ) { * }
  method resize-terminal( ) {
    rl_resize_terminal( ) }

  sub rl_set_screen_size( int32, int32 )
    is native( LIBREADLINE ) { * }
  method set-screen-size( int32 $rows, int32 $cols ) {
    rl_set_screen_size( $rows, $cols ) }

  sub rl_get_screen_size( Pointer[int32], Pointer[int32] )
    is native( LIBREADLINE ) { * }
  method get-screen-size( Pointer[int32] $rows, Pointer[int32] $cols ) {
    rl_get_screen_size( $rows, $cols ) }

  sub rl_reset_screen_size( )
    is native( LIBREADLINE ) { * }
  method reset-screen-size( ) {
    rl_reset_screen_size( ) }

  sub rl_get_termcap( Str )
    returns Str
    is native( LIBREADLINE ) { * }
  method get-termcap( Str $cap )
    returns Str {
    rl_get_termcap( $cap ) }

  # Functions for character input.
  #
  #extern int rl_getc (FILE *);
  #extern int rl_set_keyboard_input_timeout (int);

  sub rl_stuff_char( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method stuff-char( int32 $c )
    returns int32 {
    rl_stuff_char( $c ) }

  sub rl_execute_next( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method execute-next( int32 $c )
    returns int32 {
    rl_execute_next( $c ) }

  sub rl_clear_pending_input( )
    returns int32
    is native( LIBREADLINE ) { * }
  method clear-pending-input( )
    returns int32 {
    rl_clear_pending_input( ) }

  sub rl_read_key( )
    returns int32
    is native( LIBREADLINE ) { * }
  method read-key( )
    returns int32 {
    rl_read_key( ) }

  # `Public' utility functions.
  #
  sub rl_extend_line_buffer( int32 )
    is native( LIBREADLINE ) { * }
  method extend-line-buffer( int32 $len ) {
    rl_extend_line_buffer( $len ) }

  sub rl_ding( )
    returns int32
    is native( LIBREADLINE ) { * }
  method ding( )
    returns int32 {
    rl_ding( ) }

  sub rl_alphabetic( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method alphabetic( Str $c )
    returns Bool {
    rl_alphabetic( ord( $c.substr(0,1) ) ) == 1 ?? True !! False }

  sub rl_free( Pointer )
    is native( LIBREADLINE ) { * }
  method free( Pointer $mem ) {
    rl_free( $mem ) }

  # Readline signal handling, from signals.c
  #
  sub rl_set_signals( )
    returns int32
    is native( LIBREADLINE ) { * }
  method set-signals( )
    returns int32 {
    rl_set_signals( ) }

  sub rl_clear_signals( )
    returns int32
    is native( LIBREADLINE ) { * }
  method clear-signals( )
    returns int32 {
    rl_clear_signals( ) }

  sub rl_cleanup_after_signal( )
    is native( LIBREADLINE ) { * }
  method cleanup-after-signal( ) {
    rl_cleanup_after_signal( ) }

  sub rl_reset_after_signal( )
    is native( LIBREADLINE ) { * }
  method reset-after-signal( ) {
    rl_reset_after_signal( ) }

  sub rl_free_line_state( )
    is native( LIBREADLINE ) { * }
  method free-line-state( ) {
    rl_free_line_state( ) }

#  sub rl_echo_signal( int32 )
#    is native( LIBREADLINE ) { * }
#  method echo-signal( int32 $c ) {
#    rl_echo_signal( $c ) }

  sub rl_set_paren_blink_timeout( int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method set-paren-blink-timeout( int32 $c )
    returns int32 {
    rl_set_paren_blink_timeout( $c ) }

  # Completion functions.
  #
  sub rl_complete_internal( int32 ) returns int32
    is native( LIBREADLINE ) { * }
  method complete-internal( int32 $what-to-do ) returns int32 {
    rl_complete_internal( $what-to-do ) }

  sub rl_display_match_list( CArray[Str], int32, int32 )
    returns int32
    is native( LIBREADLINE ) { * }
  method display-match-list( CArray[Str] $list, int32 $a, int32 $b )
    returns int32 {
    rl_display_match_list( $list, $a, $b ) }

  sub rl_completion_matches( Str, &callback (Str, int32 --> Str) )
    returns Pointer[Str]
    is native( LIBREADLINE ) { * }
  method completion-matches( Str $text, $cb )
    returns Pointer[Str] {
    rl_completion_matches( $text, $cb ) }

  sub rl_completion_mode( &callback (int32, int32 --> int32) )
    returns int32
    is native( LIBREADLINE ) { * }
  method completion-mode( $cb )
    returns int32 {
    rl_completion_mode( $cb ) }

  ############################################################
  #  							     #
  #  		Well Published Variables		     #
  #  							     #
  ############################################################
  #
  # The version of this incarnation of the readline library.
  #
  #extern const char *rl_library_version;	/* e.g., "4.2" */
  #extern int rl_readline_version;		/* e.g., 0x0402 */

  # True if this is real GNU readline.
  #
  #extern int rl_gnu_readline_p;

  # Flags word encapsulating the current readline state.
  #
  #extern int rl_readline_state;

  # Says which editing mode readline is currently using.  1 means emacs mode;
  # 0 means vi mode.
  #
  #extern int rl_editing_mode;

  # Insert or overwrite mode for emacs mode.  1 means insert mode; 0 means
  # overwrite mode.  Reset to insert mode on each input line.
  #
  #extern int rl_insert_mode;

  # The name of the calling program.  You should initialize this to
  # whatever was in argv[0].  It is used when parsing conditionals.
  #
  #extern const char *rl_readline_name;

  # The prompt readline uses.  This is set from the argument to
  # readline (), and should not be assigned to directly.
  #
  #extern char *rl_prompt;

  # The prompt string that is actually displayed by rl_redisplay.  Public so
  # applications can more easily supply their own redisplay functions.
  #
  #extern char *rl_display_prompt;

  # The line buffer that is in use.
  #
  #extern char *rl_line_buffer;

  # The location of point, and end.
  #
  #extern int rl_point;
  #extern int rl_end;

  # The mark, or saved cursor position.
  #
  #extern int rl_mark;

  # Flag to indicate that readline has finished with the current input
  # line and should return it.
  #
  #extern int rl_done;

  # If set to a character value, that will be the next keystroke read.
  #
  #extern int rl_pending_input;

  # Non-zero if we called this function from _rl_dispatch().  It's present
  # so functions can find out whether they were called from a key binding
  # or directly from an application.
  #
  #extern int rl_dispatching;

  # Non-zero if the user typed a numeric argument before executing the
  # current function.
  #
  #extern int rl_explicit_arg;

  # The current value of the numeric argument specified by the user.
  #
  #extern int rl_numeric_arg;

  # The address of the last command function Readline executed.
  #
  #extern rl_command_func_t *rl_last_func;

  # The name of the terminal to use.
  #
  #extern const char *rl_terminal_name;

  # The input and output streams.
  #
#my $GlobalInt := cglobal('./10-cglobals', 'GlobalInt', int32);

  # XXX sizeof(FILE*) width.
  # 64-bit pointer
  our $rl_instream := cglobal( LIBREADLINE, 'rl_instream', num64 );

  #extern FILE *rl_instream;
  #extern FILE *rl_outstream;

  # If non-zero, Readline gives values of LINES and COLUMNS from the environment
  # greater precedence than values fetched from the kernel when computing the
  # screen dimensions.
  #
  #extern int rl_prefer_env_winsize;

  # If non-zero, then this is the address of a function to call just
  # before readline_internal () prints the first prompt.
  #
  #extern rl_hook_func_t *rl_startup_hook;

  # If non-zero, this is the address of a function to call just before
  # readline_internal_setup () returns and readline_internal starts
  # reading input characters.
  #
  #extern rl_hook_func_t *rl_pre_input_hook;

  # The address of a function to call periodically while Readline is
  # awaiting character input, or NULL, for no event handling.
  #
  #extern rl_hook_func_t *rl_event_hook;

  # The address of a function to call if a read is interrupted by a signal.
  #
  #extern rl_hook_func_t *rl_signal_event_hook;

  # The address of a function to call if Readline needs to know whether or not
  # there is data available from the current input source.
  #
  #extern rl_hook_func_t *rl_input_available_hook;

  # The address of the function to call to fetch a character from the current
  # Readline input stream.
  #
  #extern rl_getc_func_t *rl_getc_function;

  #extern rl_voidfunc_t *rl_redisplay_function;

  #extern rl_vintfunc_t *rl_prep_term_function;
  #extern rl_voidfunc_t *rl_deprep_term_function;

  # Dispatch variables.
  #
  #extern Keymap rl_executing_keymap;
  #extern Keymap rl_binding_keymap;

  #extern int rl_executing_key;
  #extern char *rl_executing_keyseq;
  #extern int rl_key_sequence_length;

  # Display variables.
  #
  # If non-zero, readline will erase the entire line, including any prompt,
  # if the only thing typed on an otherwise-blank line is something bound to
  # rl_newline.
  #
  #extern int rl_erase_empty_line;

  # If non-zero, the application has already printed the prompt (rl_prompt)
  # before calling readline, so readline should not output it the first time
  # redisplay is done.
  #
  #extern int rl_already_prompted;

  # A non-zero value means to read only this many characters rather than
  # up to a character bound to accept-line.
  #
  #extern int rl_num_chars_to_read;

  # The text of a currently-executing keyboard macro.
  #
  #extern char *rl_executing_macro;

  # Variables to control readline signal handling.
  #
  # If non-zero, readline will install its own signal handlers for
  # SIGINT, SIGTERM, SIGQUIT, SIGALRM, SIGTSTP, SIGTTIN, and SIGTTOU.
  #
  #extern int rl_catch_signals;

  # If non-zero, readline will install a signal handler for SIGWINCH
  # that also attempts to call any calling application's SIGWINCH signal
  # handler.  Note that the terminal is not cleaned up before the
  # application's signal handler is called; use rl_cleanup_after_signal()
  # to do that.
  #
  #extern int rl_catch_sigwinch;

  # If non-zero, the readline SIGWINCH handler will modify LINES and
  # COLUMNS in the environment.
  #
  #extern int rl_change_environment;

  # Completion variables.
  #
  # Pointer to the generator function for completion_matches ().
  # NULL means to use rl_filename_completion_function (), the default
  # filename completer.
  #
  #extern rl_compentry_func_t *rl_completion_entry_function;

  # Optional generator for menu completion.  Default is
  # rl_completion_entry_function (rl_filename_completion_function).
  #
  # extern rl_compentry_func_t *rl_menu_completion_entry_function;

  # If rl_ignore_some_completions_function is non-NULL it is the address
  # of a function to call after all of the possible matches have been
  # generated, but before the actual completion is done to the input line.
  # The function is called with one argument; a NULL terminated array
  # of (char *).  If your function removes any of the elements, they
  # must be free()'ed.
  #
  #extern rl_compignore_func_t *rl_ignore_some_completions_function;

  # Pointer to alternative function to create matches.
  # Function is called with TEXT, START, and END.
  # START and END are indices in RL_LINE_BUFFER saying what the boundaries
  # of TEXT are.
  # If this function exists and returns NULL then call the value of
  # rl_completion_entry_function to try to match, otherwise use the
  # array of strings returned.
  #
  #extern rl_completion_func_t *rl_attempted_completion_function;

  # The basic list of characters that signal a break between words for the
  # completer routine.  The initial contents of this variable is what
  # breaks words in the shell, i.e. "n\"\\'`@$>".
  #
  #extern const char *rl_basic_word_break_characters;

  # The list of characters that signal a break between words for
  # rl_complete_internal.  The default list is the contents of
  # rl_basic_word_break_characters.
  #
  #extern char *rl_completer_word_break_characters;

  # Hook function to allow an application to set the completion word
  # break characters before readline breaks up the line.  Allows
  # position-dependent word break characters.
  #
  #extern rl_cpvfunc_t *rl_completion_word_break_hook;

  # List of characters which can be used to quote a substring of the line.
  # Completion occurs on the entire substring, and within the substring   
  # rl_completer_word_break_characters are treated as any other character,
  # unless they also appear within this list.
  #
  #extern const char *rl_completer_quote_characters;

  # List of quote characters which cause a word break.
  #
  #extern const char *rl_basic_quote_characters;

  # List of characters that need to be quoted in filenames by the completer.
  #
  #extern const char *rl_filename_quote_characters;

  # List of characters that are word break characters, but should be left
  # in TEXT when it is passed to the completion function.  The shell uses
  # this to help determine what kind of completing to do.
  #
  #extern const char *rl_special_prefixes;

  # If non-zero, then this is the address of a function to call when
  # completing on a directory name.  The function is called with
  # the address of a string (the current directory name) as an arg.  It
  # changes what is displayed when the possible completions are printed
  # or inserted.  The directory completion hook should perform
  # any necessary dequoting.  This function should return 1 if it modifies
  # the directory name pointer passed as an argument.  If the directory
  # completion hook returns 0, it should not modify the directory name
  # pointer passed as an argument.
  #
  #extern rl_icppfunc_t *rl_directory_completion_hook;

  # If non-zero, this is the address of a function to call when completing
  # a directory name.  This function takes the address of the directory name
  # to be modified as an argument.  Unlike rl_directory_completion_hook, it
  # only modifies the directory name used in opendir(2), not what is displayed
  # when the possible completions are printed or inserted.  If set, it takes
  # precedence over rl_directory_completion_hook.  The directory rewrite
  # hook should perform any necessary dequoting.  This function has the same
  # return value properties as the directory_completion_hook.
  #
  # I'm not happy with how this works yet, so it's undocumented.  I'm trying
  # it in bash to see how well it goes.
  #
  #extern rl_icppfunc_t *rl_directory_rewrite_hook;

  # If non-zero, this is the address of a function for the completer to call
  # before deciding which character to append to a completed name.  It should
  # modify the directory name passed as an argument if appropriate, and return
  # non-zero if it modifies the name.  This should not worry about dequoting
  # the filename; that has already happened by the time it gets here. */
  #
  #extern rl_icppfunc_t *rl_filename_stat_hook;

  # If non-zero, this is the address of a function to call when reading
  # directory entries from the filesystem for completion and comparing
  # them to the partial word to be completed.  The function should
  # either return its first argument (if no conversion takes place) or
  # newly-allocated memory.  This can, for instance, convert filenames
  # between character sets for comparison against what's typed at the
  # keyboard.  The returned value is what is added to the list of
  # matches.  The second argument is the length of the filename to be
  # converted.
  #
  #extern rl_dequote_func_t *rl_filename_rewrite_hook;

  # If non-zero, then this is the address of a function to call when
  # completing a word would normally display the list of possible matches.
  # This function is called instead of actually doing the display.
  # It takes three arguments: (char **matches, int num_matches, int max_length)
  # where MATCHES is the array of strings that matched, NUM_MATCHES is the
  # number of strings in that array, and MAX_LENGTH is the length of the
  # longest string in that array.
  #
  #extern rl_compdisp_func_t *rl_completion_display_matches_hook;

  # Non-zero means that the results of the matches are to be treated
  # as filenames.  This is ALWAYS zero on entry, and can only be changed
  # within a completion entry finder function.
  #
  #extern int rl_filename_completion_desired;

  # Non-zero means that the results of the matches are to be quoted using
  # double quotes (or an application-specific quoting mechanism) if the
  # filename contains any characters in rl_word_break_chars.  This is
  # ALWAYS non-zero on entry, and can only be changed within a completion
  # entry finder function.
  #
  #extern int rl_filename_quoting_desired;

  # Set to a function to quote a filename in an application-specific fashion.
  # Called with the text to quote, the type of match found (single or multiple)
  # and a pointer to the quoting character to be used, which the function can
  # reset if desired.
  #
  #extern rl_quote_func_t *rl_filename_quoting_function;

  # Function to call to remove quoting characters from a filename.  Called
  # before completion is attempted, so the embedded quotes do not interfere
  # with matching names in the file system.
  #
  #extern rl_dequote_func_t *rl_filename_dequoting_function;

  # Function to call to decide whether or not a word break character is
  # quoted.  If a character is quoted, it does not break words for the
  # completer.
  #
  #extern rl_linebuf_func_t *rl_char_is_quoted_p;

  # Non-zero means to suppress normal filename completion after the
  # user-specified completion function has been called.
  #
  #extern int rl_attempted_completion_over;

  # Set to a character describing the type of completion being attempted by
  # rl_complete_internal; available for use by application completion
  # functions.
  #
  #extern int rl_completion_type;

  # Set to the last key used to invoke one of the completion functions.
  #
  #extern int rl_completion_invoking_key;

  # Up to this many items will be displayed in response to a
  # possible-completions call.  After that, we ask the user if she
  # is sure she wants to see them all.  The default value is 100.
  #
  #extern int rl_completion_query_items;

  # Character appended to completed words when at the end of the line.  The
  # default is a space.  Nothing is added if this is '\0'.
  #
  #extern int rl_completion_append_character;

  # If set to non-zero by an application completion function,
  # rl_completion_append_character will not be appended.
  #
  #extern int rl_completion_suppress_append;

  # Set to any quote character readline thinks it finds before any application
  # completion function is called.
  #
  #extern int rl_completion_quote_character;

  # Set to a non-zero value if readline found quoting anywhere in the word to
  # be completed; set before any application completion function is called.
  #
  #extern int rl_completion_found_quote;

  # If non-zero, the completion functions don't append any closing quote.
  # This is set to 0 by rl_complete_internal and may be changed by an
  # application-specific completion function.
  #
  #extern int rl_completion_suppress_quote;

  # If non-zero, readline will sort the completion matches.  On by default.
  #
  #extern int rl_sort_completion_matches;

  # If non-zero, a slash will be appended to completed filenames that are
  # symbolic links to directory names, subject to the value of the
  # mark-directories variable (which is user-settable).  This exists so
  # that application completion functions can override the user's preference
  # (set via the mark-symlinked-directories variable) if appropriate.
  # It's set to the value of _rl_complete_mark_symlink_dirs in
  # rl_complete_internal before any application-specific completion
  # function is called, so without that function doing anything, the user's
  # preferences are honored.
  #
  #extern int rl_completion_mark_symlink_dirs;

  # If non-zero, then disallow duplicates in the matches.
  #
  #extern int rl_ignore_completion_duplicates;

  # If this is non-zero, completion is (temporarily) inhibited, and the
  # completion character will be inserted as any other.
  #
  #extern int rl_inhibit_completion;

  # Input error; can be returned by (*rl_getc_function) if readline is reading
  # a top-level command (RL_ISSTATE (RL_STATE_READCMD)).

  constant READERR = -2;

  # Definitions available for use by readline clients.
  #
  constant RL_PROMPT_START_IGNORE = '\001';
  constant RL_PROMPT_END_IGNORE   = '\002';

  # Possible values for do_replace argument to rl_filename_quoting_function,
  # called by rl_complete_internal.
  #
  constant NO_MATCH     = 0;
  constant SINGLE_MATCH = 1;
  constant MULT_MATCH   = 2;

  # Possible state values for rl_readline_state
  #
  constant RL_STATE_NONE	 = 0x0000000; # no state; before first call 

  constant RL_STATE_INITIALIZING = 0x0000001; # initializing
  constant RL_STATE_INITIALIZED	 = 0x0000002; # initialization done
  constant RL_STATE_TERMPREPPED	 = 0x0000004; # terminal is prepped
  constant RL_STATE_READCMD	 = 0x0000008; # reading a command key
  constant RL_STATE_METANEXT	 = 0x0000010; # reading input after ESC
  constant RL_STATE_DISPATCHING	 = 0x0000020; # dispatching to a command
  constant RL_STATE_MOREINPUT	 = 0x0000040; # reading more input in a command function
  constant RL_STATE_ISEARCH	 = 0x0000080; # doing incremental search
  constant RL_STATE_NSEARCH	 = 0x0000100; # doing non-inc search
  constant RL_STATE_SEARCH	 = 0x0000200; # doing a history search
  constant RL_STATE_NUMERICARG	 = 0x0000400; # reading numeric argument
  constant RL_STATE_MACROINPUT	 = 0x0000800; # getting input from a macro
  constant RL_STATE_MACRODEF	 = 0x0001000; # defining keyboard macro
  constant RL_STATE_OVERWRITE	 = 0x0002000; # overwrite mode
  constant RL_STATE_COMPLETING	 = 0x0004000; # doing completion
  constant RL_STATE_SIGHANDLER	 = 0x0008000; # in readline sighandler
  constant RL_STATE_UNDOING	 = 0x0010000; # doing an undo
  constant RL_STATE_INPUTPENDING = 0x0020000; # rl_execute_next called 
  constant RL_STATE_TTYCSAVED	 = 0x0040000; # tty special chars saved
  constant RL_STATE_CALLBACK	 = 0x0080000; # using the callback interface
  constant RL_STATE_VIMOTION	 = 0x0100000; # reading vi motion arg
  constant RL_STATE_MULTIKEY	 = 0x0200000; # reading multiple-key command
  constant RL_STATE_VICMDONCE	 = 0x0400000; # entered vi command mode at least once
  constant RL_STATE_REDISPLAYING = 0x0800000; # updating terminal display

  constant RL_STATE_DONE	 = 0x1000000; # done; accepted line

  #define RL_SETSTATE(x)	(rl_readline_state |= (x))
  #define#RL_UNSETSTATE(x)	(rl_readline_state &= ~(x))
  #define RL_ISSTATE(x)		(rl_readline_state & (x))

  my class readline_state is repr('CStruct') {
    # line state
    has int $.point;  # int point;
    has int $.end;    # int end;
    has int $.mark;   # int mark;
    has Str $.buffer; # char *buffer;
    has int $.buflen; # int buflen;
    has Pointer $.ul; # UNDO_LIST *ul;
    has Str $.prompt; # char *prompt;

    # global state
    has int $.rlstate; # int rlstate;
    has int $.done; # int done;
    has Pointer $.keymap; # Keymap kmap;

    # input state
    has Pointer $.lastfunc; # rl_command_func_t *lastfunc;
    has int $.insmode;      # int insmode;
    has int $.edmode;       # int edmode;
    has int $.kseqlen;      # int kseqlen;
    has Pointer $.inf;      # FILE *inf;
    has Pointer $.outf;     # FILE *outf;
    has int $.pendingin;    # int pendingin;
    has Str $.macro;        # char *macro;

    # signal state
    has int $.catchsigs;     # int catchsigs;
    has int $.catchsigwinch; # int catchsigwinch;

    # search state

    # completion state

    # options state

    # reserved for future expansion, so the struct size doesn't change
    has int $.reserved; # char reserved[64]; # XXX
  }

  sub rl_save_state( readline_state )
    returns int32
    is native( LIBREADLINE ) { * }
  method save-state( readline_state $state )
    returns int32 {
    rl_save_state( $state ) }

  sub rl_restore_state( readline_state )
    returns int32
    is native( LIBREADLINE ) { * }
  method restore-state( readline_state $state )
    returns int32 {
    rl_restore_state( $state ) }

  ############################################################################
  #
  # rltypedefs.h -- Type declarations for readline functions. */
  #
  # Typedefs for the completion system
  #
  #typedef char *rl_compentry_func_t (const char *, int);
  #typedef char **rl_completion_func_t (const char *, int, int);

  #typedef char *rl_quote_func_t (char *, int, char *);
  #typedef char *rl_dequote_func_t (char *, int);

  #typedef int rl_compignore_func_t (char **);

  #typedef void rl_compdisp_func_t (char **, int, int);

  # Type for input and pre-read hook functions like rl_event_hook
  #
  #typedef int rl_hook_func_t (void);

  # Input function type
  #
  #typedef int rl_getc_func_t (FILE *);

  # Generic function that takes a character buffer (which could be the readline
  # line buffer) and an index into it (which could be rl_point) and returns
  # an int.
  #
  #typedef int rl_linebuf_func_t (char *, int);

  # `Generic' function pointer typedefs
  #
  #typedef int rl_icppfunc_t (char **);

  #typedef void rl_voidfunc_t (void);
  #typedef void rl_vintfunc_t (int);
  #typedef void rl_vcpfunc_t (char *);
  #
  #typedef char *rl_cpvfunc_t (void);

  #############################################################################
  #
  # tilde.h: Externally available variables and function in libtilde.a.
  #
  #typedef char *tilde_hook_func_t (char *);

  # If non-null, this contains the address of a function that the application
  # wants called before trying the standard tilde expansions.  The function
  # is called with the text sans tilde, and returns a malloc()'ed string
  # which is the expansion, or a NULL pointer if the expansion fails.
  #
  #extern tilde_hook_func_t *tilde_expansion_preexpansion_hook;

  # If non-null, this contains the address of a function to call if the
  # standard meaning for expanding a tilde fails.  The function is called
  # with the text (sans tilde, as in "foo"), and returns a malloc()'ed string
  # which is the expansion, or a NULL pointer if there is no expansion.
  #
  #extern tilde_hook_func_t *tilde_expansion_failure_hook;

  # When non-null, this is a NULL terminated array of strings which
  # are duplicates for a tilde prefix.  Bash uses this to expand
  # `=~' and `:~'.
  #
  #extern char **tilde_additional_prefixes;

  # When non-null, this is a NULL terminated array of strings which match
  # the end of a username, instead of just "/".  Bash sets this to
  # `:' and `=~'.
  #
  #extern char **tilde_additional_suffixes;

  # Return a new string which is the result of tilde expanding STRING.
  #
  sub tilde_expand( Str )
    returns Str
    is native( LIBREADLINE ) { * }
  method tilde-expand( Str $filename )
    returns Str {
    tilde_expand( $filename ) }

  sub tilde_expand_word( Str )
    returns Str
    is native( LIBREADLINE ) { * }
  method tilde-expand-word( Str $filename )
    returns Str {
    tilde_expand_word( $filename ) }

  sub tilde_find_word( Str, int32, Pointer[int32] ) returns Str
    is native( LIBREADLINE ) { * }
  method tilde-find-word( Str $str, int32 $offset, Pointer[int32] $p-offset )
    returns Str {
      tilde_find_word( $str, $offset, $p-offset ) }
}
