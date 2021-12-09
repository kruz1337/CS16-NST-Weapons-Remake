/**
 * String Stocks
 * Version 0.0.6
 * by Exolent
 * 
 * These functions are designed to make using strings much easier
 * and fulfill any string manipulation you may need.
 * 
 * Functions:
 * 
 * @function	is_str_empty(const string[])
 * @info	Checks if a given string is empty
 * @return	True if empty
 * 		False otherwise
 * 
 * @function	is_str_num(const string[])
 * @info	Checks if a given string is an integer
 * @return	True if integer
 * 		False otherwise
 * 
 * @function	is_str_alpha(const string[])
 * @info	Checks if a given string contains only letters
 * @return	True if only contains letters
 * 		False otherwise
 * 
 * @function	is_str_alnum(const string[])
 * @info	Checks if a given string contains only letters and digits (alphanumeric)
 * @return	True if alphanumeric
 * 		False otherwise
 * 
 * @function	is_str_spaces(const string[])
 * @info	Checks if a given string contains only whitespace characters (these carriage returns, new line feeds, tabs, and spaces)
 * @return	True if whitespace characters only
 * 		False otherwise
 * 
 * @function	is_char(c)
 * @info	Checks if a given character is a valid ASCII value
 * @return	True if valid character
 * 		False otherwise
 * 
 * @function	is_char_upper(c)
 * @info	Checks if a given character is an uppercase letter
 * @return	True if uppercase
 * 		False otherwise
 * 
 * @function	is_char_lower(c)
 * @info	Checks if a given character is an lowercase letter
 * @return	True if uppercase
 * 		False otherwise
 * 
 * @function	strrfind(const string[], const sub[], ignorecase = 0, pos = 0)
 * @info	Finds the last occurrence of "sub" in "string" starting at "pos"
 * @params	ignorecase - If 0, string comparing is case sensitive, otherwise it is case insensitive
 * 		pos - The minimum position in "string" that "sub" can be found
 * @return	If found, the index (starting at 0) in which "sub" starts in "string".
 * 		-1 if not found
 * 
 * @function	str_substr(const string[], start, output[], output_len, len = 0)
 * @info	Retrieves a piece of "string" and stores it into "output" for "len" max characters
 * @params	start - The index of "string" where "output" starts
 * 		len - The length of the piece of "string" to return (if greater than "output_len", then "output_len" is the max; if 0, then "len" is assumed to be as long as possible)
 * @return	Returns the number of characters stored in "output"
 * 
 * @function	str_explode(const string[], delimiter, output[][], output_size, output_len)
 * @info	Explodes "string" at each "delimiter" character, and stores the pieces into "output" array
 * @params	output_size - The maximum pieces to store in the output array
 * 		output_len - The maximum length of a piece to store in the output array
 * @return	Returns the number of pieces stored into the output array
 * 
 * @function	str_explode_str(const string[], const delimiter[], const output[], output_size, output_len)
 * @info	The same as str_explode(), except the delimiter is a string.
 * 
 * @function	str_implode(const input[][], size, delimiter, output[], output_len)
 * @info	Combines all strings from the input array, separating them by a delimiter, and storing the result into output
 * @params	size - The number of strings in the input array (This is not the max size of the input array, but only the number of strings!)
 * 		delimiter - The character to separate strings
 * 		output_len - The maximum length of the output string
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_implode_str(const input[][], size, const delimiter[], output[], output_len)
 * @info	Combines all strings from the input array, separating them by a delimiter, and storing the result into output
 * @params	size - The number of strings in the input array (This is not the max size of the input array, but only the number of strings!)
 * 		delimiter - The string to separate strings
 * 		output_len - The maximum length of the output string
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_insert(const string[], const input[], pos, output[], output_len)
 * @info	Inserts "input" string into the "string" string at the "pos" index of "string" and stores the result in "output"
 * @params	output_len - The max length of the output string
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_cat(output[], output_len, ...)
 * @info	Concatenates all strings passed into the output string
 * @params	output_len - The max length of the output string
 * 		... - All strings to be concatenated as extra params
 * @example	str_cat(output, charsmax(output), "This is ", "a", " test.")
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_parsetok(const text[], token = ' ', trimSpaces = 0, ...)
 * @info	Parses "text" into pieces separated by "token" character, storing the pieces into additional params supplied
 * @params	trimSpaces - If 1, then extra spaces around the pieces are not stored with the pieces
 * 		... - All output strings which store pieces, individually followed by their max length
 * @example	str_parsetok("This is; a test", ';', 1, string1, charsmax(string1), string2, charsmax(string2)) // string1[] = "This is", string2[] = "a test"
 * @return	Returns the total number if pieces parsed.
 * 
 * @function	str_delete(string[], chars, pos)
 * @info	Deletes a piece of a string for "chars" length starting at "pos"
 * @params	chars - The number of characters to delete (set to 0 to delete from "pos" to the end of the string)
 * 		pos - The start position to delete from
 * @return	Returns the new length of the string
 * 
 * @function	str_replace(string[], string_len, const what[], const with[], max_replace = 0, ignorecase = 0)
 * @info	Replaces "what" with "with" inside of "string"
 * @params	max_replace - The maximum number of replacements (set to 0 for unlimited)
 * 		ignorecase - If 0, string comparing is case sensitive, otherwise it is case insensitive
 * @return	Returns the total number of replacements
 * 
 * @function	is_str_type(const string[], StrType:flags, const exceptions[] = "")
 * @info	Checks if a string matches the StrType flags, ignoring characters in "exceptions"
 * @params	flags - A bitsum value containing STRTYPE_* constants
 * 		exceptions - A string containing characters you want ignored from being checked
 * @example	is_str_type("bad.demo.name%!.dem", (STRTYPE_NUM | STRTYPE_ALPHA), "_-.") // checks if a string is safe for a demo name, only allowing letters, numbers, underscores, dashes, and periods
 * @return	True if matches the flags
 * 		False otherwise
 * 
 * @function	is_str_float(const string[])
 * @info	Checks if a given string is safe to be a float value
 * @return	True if a float
 * 		False otherwise
 * 
 * @function	add_commas({Float,_}:value, output[], output_len, bool:is_float = false)
 * @info	Adds commas to a given float/integer value and stores it into "output" string
 * @params	value - Can be a float value or integer value
 * 		output_len - The max length of the output string
 * 		is_float - Set to true for floats, and false for integers
 * @example	add_commas(1234.56789, output, charsmax(output),  true) // would give "1,234.56789
 * 		add_commas(12345678, output, charsmax(output)) // would give 12,345,678
 * @return	Returns the number of characters stored into the output string
 * 
 * @function	str_addcommas(const string[], output[], output_len)
 * @info	Adds commas to a given string containing a float or integer value and stores it into the "output" string
 * @params	output_len - The max length of the output string
 * @return	Returns the number of characters stored into the output string
 * 
 * @function	str_ltrim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
 * @info	Trims characters from the left side of the string
 * 		Default trims whitespace characters
 * @return	Returns the new length of the string
 * 
 * @function	str_rtrim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
 * @info	Trims characters from the right side of the string
 * 		Default trims whitespace characters
 * @return	Returns the new length of the string
 * 
 * @function	str_trim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
 * @info	Trims characters from both sides of the string
 * 		Default trims whitespace characters
 * @return	Returns the new length of the string
 * 
 * @function	str_pad(const string[], pad_size, output[], output_len, const pad_string[] = " ", StrPad:pad_flags = (STRPAD_LEFT | STRPAD_RIGHT))
 * @info	Pads a string with "pad_string" for "pad_size" length on left and/or right sides of the string (based on the pad_flags)
 * @params	pad_size - The number of characters of the pad
 * 		output - The padded string
 * 		output_len - The max length of the output string
 * 		pad_string - The string to use for padding
 * 		pad_flags - The flags which determine 
 * @example	str_pad("12345", 2, output, charsmax(output), ":") // would give "::12345::")
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_lpad(const string[], pad_size, output[], output_len, const pad_string[] = " ")
 * @info	Pads a string only on the left side
 * 		See str_pad() for more information
 * 
 * @function	str_rpad(const string[], pad_size, output[], output_len, const pad_string[] = " ")
 * @info	Pads a string only on the right side
 * 		See str_pad() for more information
 * 
 * @function	str_repeat(const string[], times, output[], output_len)
 * @info	Repeats a given string for "times" times and stores the result into the "output" string
 * @param	times - Number of times to repeat, set 0 to repeat until output buffer is filled
 * @example	str_repeat("HA", 10, output, charsmax(output)) // would give "HAHAHAHAHAHAHAHAHAHA"
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_shuffle(string[])
 * @info	Randomizes the characters in a string
 * @return	Returns the length of the string
 * 
 * @function	str_substr_count(const string[], const find[], start = 0, len = 0)
 * @info	Counts the number of times "find" occurs in "string"
 * @params	start - The starting position to look in "string"
 * 		len - The max length of characters to look in after "start" (set to 0 for the whole string)
 * @return	Returns the number of times "find" is found in "string"
 * 
 * @function	str_ucwords(string[])
 * @info	Capitalizes the first character of every word in the string
 * @return	Returns the length of the string
 * 
 * @function	str_wordwrap(const string[], output[], output_len, width = 75, const wrapper[] = "^n", bool:cut = false)
 * @info	Wraps a string to a specific width, adding a wrapper between each wrapped section, like word wrap in a text file
 * @params	width - The max width of each wrapped section
 * 		wrapper - The string to wrap each section, normally a new line feed
 * 		cut - If true, then words will be cut if needed to fit the width. Otherwise, the word will be put into the next section so the width isn't surpassed.
 * @example	str_wordwrap("Vertical Text", output, charsmax(output), 1, "^n", true) // turns "Vertical Text" so each character is on its own line
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_empty(string[], length = 0)
 * @info	Empties a string at a given length
 * @params	length - The max length for the string to have (0 empties the string completely)
 * @return	No return value
 * 
 * @function	str_uriencode(const string[], output[], output_len)
 * @info	Encodes a string for a URI
 * @return	Returns the total characters stored into the output string
 * 
 * @function	str_uridecode(const string[], output[], output_len)
 * @info	Decodes a string from a URI encoding
 * @return	Returns the total characters stored into the output string
 * 
 * @function	is_str_upper(const string[])
 * @info	Checks if a given string is all uppercase letters
 * @return	True if uppercase
 * 		False otherwise, or an empty string
 * 
 * @function	is_str_lower(const string[])
 * @info	Checks if a given string is all lowercase letters
 * @return	True if uppercase
 * 		False otherwise, or an empty string
 * 
 * @function	regex_escape(const string[], output[], output_len)
 * @info	Escapes a string to be used in a regex pattern
 * @return	Returns the length of the output string
 * 
 * @function	parse_color(const color[], &r = 0, &g = 0, &b = 0)
 * @info	Parses a string for several color formats
 * 		Currently supports "R,G,B", "RRRGGGBBB", hex (both long "#0099ff" and short "#09f", case insensitive)
 * 		On failure, the RGB return values are set to 0,0,0
 * @return	1 on success, 0 on failure
 * 
 * @function	html_encode(const string[], output[], output_len)
 * @info	Encodes a string to be HTML-compatible.
 * @return	Returns the length of the output string.
 * 
 * @function	html_decode(const string[], output[], output_len)
 * @info	Decodes a string from being HTML-compatible to its original contents
 * @return	Returns the length of the output string.
 */
#if defined _string_stocks_included
	#endinput
#endif

#define _string_stocks_included

#include <amxmodx>
#include <regex>

enum StrType (<<= 1)
{
	STRTYPE_NUM = 1,
	STRTYPE_ALPHA,
	STRTYPE_SPACE
};

enum StrPad (<<= 1)
{
	STRPAD_LEFT = 1,
	STRPAD_RIGHT
};

#define is_str_empty(%1) (%1[0] == EOS)

#define is_str_num(%1) is_str_type((%1), STRTYPE_NUM)
#define is_str_alpha(%1) is_str_type((%1), STRTYPE_ALPHA)
#define is_str_alnum(%1) is_str_type((%1), (STRTYPE_NUM | STRTYPE_ALPHA))
#define is_str_spaces(%1) is_str_type((%1), STRTYPE_SPACE)

#define is_char(%1) (0 < (%1) <= 255)
//#define is_char_upper(%1) (is_char((%1)) && (65 <= (%1) <= 90))
stock bool:is_char_upper(c)
{
	return (is_char(c) && ('A' <= c <= 'Z'));
}
//#define is_char_lower(%1) (is_char((%1)) && (65 <= (%1) <= 90))
stock bool:is_char_lower(c)
{
	return (is_char(c) && ('a' <= c <= 'z'));
}

stock __temp_string[1024];
stock __temp_string2[1024];

stock const __html_entities[][2][] =
{
	{"&", "&amp;"},
	{"<", "&lt;"},
	{">", "&gt;"}
};

stock bool:__set_html_len = false;
stock __html_len[sizeof(__html_entities)];

stock strrfind(const string[], const sub[], ignorecase = 0, pos = 0)
{
	new ret = -1;
	
	while((pos = strfind(string, sub, ignorecase, pos)) >= 0)
	{
		ret = pos++;
	}
	
	return ret;
}

stock str_substr(const string[], start, output[], output_len, len = 0)
{
	if(len == 0 || len > output_len)
	{
		len = output_len;
	}
	
	return copy(output, len, string[start]);
}

stock str_explode(const string[], delimiter, output[][], output_size, output_len)
{
	new i, pos, len = strlen(string);
	
	do
	{
		pos += (copyc(output[i++], output_len, string[pos], delimiter) + 1);
	}
	while(pos < len && i < output_size);
	
	return i;
}

stock str_explode_str(const string[], const delimiter[], output[][], output_size, output_len)
{
	new delimiter_len = strlen(delimiter);
	
	if(delimiter_len < 1)
	{
		return 0;
	}
	else if(delimiter_len == 1)
	{
		return str_explode(string, delimiter[0], output, output_size, output_len);
	}
	
	new i, pos, stop, len = strlen(string);
	
	do
	{
		stop = contain(string[pos], delimiter) + pos;
		
		if(stop < pos)
		{
			stop = len;
		}
		
		str_substr(string, pos, output[i], output_len, stop - pos);
		
		pos = stop + delimiter_len;
	}
	while(pos < len && ++i < output_size);
	
	return i;
}

stock str_implode(const input[][], size, delimiter, output[], output_len)
{
	new delimiter_str[2];
	delimiter_str[0] = delimiter;
	
	return str_implode_str(input, size, delimiter_str, output, output_len);
}

stock str_implode_str(const input[][], size, const delimiter[], output[], output_len)
{
	if(size < 1)
	{
		return 0;
	}
	
	new pos = copy(output, output_len, input[0]);
	
	for(new i = 1; i < size; i++)
	{
		pos += formatex(output[pos], output_len - pos, "%s%s", delimiter, input[i]);
	}
	
	return pos;
}

stock str_insert(const string[], const input[], pos, output[], output_len)
{
	if(pos > output_len)
	{
		return 0;
	}
	
	copy(output, pos, string);
	add(output, output_len, input);
	return add(output, output_len, string[pos]);
}

stock str_cat(output[], output_len, ...)
{
	new argc = numargs();
	
	new len, c;
	
	str_empty(output);
	
	for(new i = 2; i <= argc; i++)
	{
		len = 0;
		
		while(len < charsmax(__temp_string) && is_char(c = getarg(i, len)))
		{
			__temp_string[len++] = c;
		}
		
		str_empty(__temp_string, len);
		
		len = add(output, output_len, __temp_string);
	}
	
	return len;
}

stock str_parsetok(const text[], token = ' ', trimSpaces = 0, ...)
{
	new argc = numargs();
	
	if(argc < 5)
	{
		return 0;
	}
	
	new find[2];
	find[0] = token;
	
	new text_len = strlen(text);
	new start, stop;
	new arg_string_index = 3;
	new arg_len_index = 4;
	new parse_count, arg_len, i;
	
	while(arg_string_index < argc && arg_len_index < argc && start < text_len)
	{
		while(trimSpaces && text[start] == ' ' && start < text_len)
		{
			start++;
		}
		
		stop = contain(text[start], find) + start;
		
		if(stop < start) stop = text_len;
		
		arg_len = min(getarg(arg_len_index), stop - start);
		
		if(arg_len > 0)
		{
			for(i = 0; i < arg_len; i++)
			{
				setarg(arg_string_index, i, text[start + i]);
			}
			
			setarg(arg_string_index, arg_len, EOS);
		}
		
		start = stop + 1;
		
		arg_string_index += 2;
		arg_len_index += 2;
		
		parse_count++;
	}
	
	return parse_count;
}

stock str_delete(string[], chars, pos)
{
	new len = strlen(string);
	
	if(chars <= 0)
	{
		chars = len - pos;
	}
	
	if((pos + chars) >= len)
	{
		len = pos;
	}
	else
	{
		new i;
		for(i = pos + chars; i < len; i++)
		{
			string[i - chars] = string[i];
		}
		
		len = i - chars;
	}
	
	str_empty(string, len);
	
	return len;
}

stock str_replace(string[], string_len, const what[], const with[], max_replace = 0, ignorecase = 0)
{
	copy(__temp_string, charsmax(__temp_string), string);
	
	new what_len = strlen(what);
	
	new pos = -1, total;
	while((pos = strfind(__temp_string, what, ignorecase, pos + 1)) >= 0 && (!max_replace || total < max_replace))
	{
		str_delete(__temp_string, what_len, pos);
		str_insert(__temp_string, with, pos, __temp_string2, charsmax(__temp_string2));
		
		copy(__temp_string, charsmax(__temp_string), __temp_string2);
		
		total++;
	}
	
	copy(string, string_len, __temp_string);
	
	return total;
}

stock bool:is_str_type(const string[], StrType:flags, const exceptions[] = "")
{
	new c, i, tmp[2];
	while(is_char(c = string[i++]))
	{
		if(flags & STRTYPE_NUM && isdigit(c)
		|| flags & STRTYPE_ALPHA && isalpha(c)
		|| flags & STRTYPE_SPACE && isspace(c))
		{
			continue;
		}
		
		tmp[0] = c;
		if(contain(exceptions, tmp) != -1)
		{
			continue;
		}
		
		return false;
	}
	
	return (i > 1);
}

stock bool:is_str_float(const string[])
{
	new c, i, p;
	while(is_char(c = string[i++]))
	{
		if(!isdigit(c))
		{
			if(c != '.' || p)
			{
				return false;
			}
			
			p = 1;
		}
	}
	
	return (i > 1);
}

stock add_commas({Float,_}:value, output[], output_len, bool:is_float = false)
{
	if(is_float)
	{
		float_to_str(Float:value, __temp_string, charsmax(__temp_string));
	}
	else
	{
		num_to_str(_:value, __temp_string, charsmax(__temp_string));
	}
	
	return str_addcommas(__temp_string, output, output_len);
}

stock str_addcommas(const string[], output[], output_len)
{
	new stop = contain(string, ".");
	
	if(stop == -1)
	{
		stop = strlen(string);
	}
	
	new start, o, i;
	
	if(string[0] == '-')
	{
		output[o++] = '-';
		start = i = 1;
	}
	
	while(i < stop && o < output_len)
	{
		output[o++] = string[i++];
		
		if(o < output_len && i < stop && ((stop - i - start) % 3) == 0)
		{
			output[o++] = ',';
		}
	}
	
	if(o < output_len)
	{
		o += copy(output[o], output_len - o, string[stop]);
	}
	
	return o;
}

stock str_ltrim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
{
	new tmp[2];
	new i;
	
	while(is_char(tmp[0] = string[i]) && strfind(trim, tmp, ignorecase) >= 0)
	{
		i++;
	}
	
	return i ? str_delete(string, i, 0) : 0;
}

stock str_rtrim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
{
	new len = strlen(string);
	new i = len;
	new tmp[2];
	
	while(is_char(tmp[0] = string[--i]) && strfind(trim, tmp, ignorecase) >= 0) { }
	
	if(++i < len)
	{
		str_empty(string, i);
	}
	
	return i;
}

stock str_trim(string[], const trim[] = " ^n^t^r", ignorecase = 0)
{
	str_ltrim(string, trim, ignorecase);
	return str_rtrim(string, trim, ignorecase);
}

stock str_pad(const string[], pad_size, output[], output_len, const pad_string[] = " ", StrPad:pad_flags = (STRPAD_LEFT | STRPAD_RIGHT))
{
	if(pad_size > output_len)
	{
		pad_size = output_len;
	}
	
	new len;
	
	str_empty(output);
	
	if(pad_flags & STRPAD_LEFT)
	{
		while(len < pad_size)
		{
			len = add(output, pad_size, pad_string);
		}
	}
	
	len = add(output, output_len, string);
	
	if(pad_flags & STRPAD_RIGHT)
	{
		output_len = min(output_len, (len + pad_size));
		
		while(len < output_len)
		{
			len = add(output, output_len, pad_string);
		}
	}
	
	return len;
}

stock str_lpad(const string[], pad_size, output[], output_len, const pad_string[] = " ")
{
	return str_pad(string, pad_size, output, output_len, pad_string, STRPAD_LEFT);
}

stock str_rpad(const string[], pad_size, output[], output_len, const pad_string[] = " ")
{
	return str_pad(string, pad_size, output, output_len, pad_string, STRPAD_RIGHT);
}

stock str_repeat(const string[], times, output[], output_len)
{
	new len;
	
	str_empty(output);
	
	if(times > 0)
	{
		do
		{
			len = add(output, output_len, string);
		}
		while(--times);
	}
	else
	{
		while(len < output_len)
		{
			len = add(output, output_len, string);
		}
	}
	
	return len;
}

stock str_shuffle(string[])
{
	new len = strlen(string);
	SortCustom1D(string, len, "_str_shuffle");
	return len;
}

public _str_shuffle(item1, item2, array[])
{
	return ((random(2) * 2) - 1);
}

stock str_substr_count(const string[], const find[], start = 0, len = 0)
{
	new find_len = strlen(find);
	
	if(!find_len)
	{
		return 0;
	}
	
	new string_len = strlen(string);
	
	if(!len)
	{
		len = string_len - start;
	}
	
	if(find_len > len || string_len < (len + start))
	{
		return 0;
	}
	
	new i, count, last = start;
	
	while(last < string_len && (i = contain(string[last], find) + last) >= last && (i - start) <= len)
	{
		count++;
		
		last = i + find_len;
	}
	
	return count;
}

stock str_ucwords(string[])
{
	new c, i, bool:space = true; // set to space already for first word in string
	
	while(is_char(c = string[i]))
	{
		 // ignore hyphenated words, emails, contractions
		if(isalpha(c) || isdigit(c) || c == '-' || c == '@' || c == ''')
		{
			if(space)
			{
				string[i] = toupper(c);
			}
			else
			{
				space = false;
			}
		}
		else
		{
			space = true;
		}
		
		i++;
	}
	
	return i;
}

stock str_wordwrap(const string[], output[], output_len, width = 75, const wrapper[] = "^n", bool:cut = false)
{
	if(width <= 0)
	{
		width = 75;
	}
	
	new string_len = strlen(string);
	new pos;
	
	if(cut)
	{
		for(new i = 0; i < string_len && pos < output_len; i++)
		{
			output[pos++] = string[i];
			
			if((i % width) == 0)
			{
				pos = add(output, output_len, wrapper);
			}
		}
	}
	else
	{
		new c, start, last;
		
		for(new i = 0; i < string_len && pos < output_len; i++)
		{
			c = string[i];
			
			if(isspace(c))
			{
				if((pos - start) > width)
				{
					if(last)
					{
						str_insert(output, wrapper, last, __temp_string, charsmax(__temp_string));
						pos = copy(output, output_len, __temp_string);
						last = 0;
					}
				}
				else if((pos - start) == width)
				{
					pos = add(output, output_len, wrapper);
					last = 0;
				}
				else
				{
					output[pos] = c;
					last = pos++;
				}
			}
			else
			{
				output[pos++] = c;
			}
		}
	}
	
	return pos;
}

stock str_empty(string[], length = 0)
{
	string[length] = EOS;
	return length;
}

stock str_uriencode(const string[], output[], output_len)
{
	new const hexchars[] = {48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70};
	
	new c, i, pos;
	while(is_char(c = string[i]) && pos < output_len)
	{
		if(c == ' ')
		{
			output[pos++] = '+';
		}
		else if(!isdigit(c) && !isalpha(c))
		{
			if((pos + 3) > output_len)
			{
				break;
			}
			
			output[pos++] = '%';
			output[pos++] = hexchars[c >> 4];
			output[pos++] = hexchars[c & 0xF];
		}
		else
		{
			output[pos++] = c;
		}
		
		i++;
	}
	
	str_empty(output, pos);
	
	return i;
}

stock str_uridecode(const string[], output[], output_len)
{
	new c, i, pos;
	while(is_char(c = string[i++]) && pos < output_len)
	{
		if(c == '+')
		{
			output[pos++] = ' ';
		}
		else if(c == '%')
		{
			c = string[i++];
			output[pos] = ((c < 65) ? (c - 48) : (c - 65)) << 4;
			c = string[i++];
			output[pos++] |= (c < 65) ? (c - 48) : (c - 65);
		}
		else
		{
			output[pos++] = c;
		}
	}
	
	return pos;
}

stock bool:is_str_upper(const string[])
{
	new i;
	while(is_char_upper(string[i]))
	{
		i++;
	}
	
	return (i > 0 && !is_char(string[i]));
}

stock bool:is_str_lower(const string[])
{
	new i;
	while(is_char_lower(string[i]))
	{
		i++;
	}
	
	return (i > 0 && !is_char(string[i]));
}

stock regex_escape(const string[], output[], output_len)
{
	new c, i, p;
	while(p < output_len && is_char(c = string[i++]))
	{
		if(!isdigit(c) && !isalpha(c) && !isspace(c))
		{
			if((p + 2) > output_len)
			{
				break;
			}
			
			output[p++] = '\';
		}
		
		output[p++] = c;
	}
	
	return p;
}

stock parse_color(const color[], &r = 0, &g = 0, &b = 0)
{
	new colors[3];
	new valid = 1;
	new regexReturn;
	
	if(regex_match(color, "^^([0-1][0-9][0-9]|2([0-4][0-9]|5[0-5])){3}$", regexReturn, "", 0) >= REGEX_OK)
	{
		new long = str_to_num(color);
		
		colors[0] = long / 1000000;
		colors[1] = (long / 1000) % 1000;
		colors[2] = long % 1000;
	}
	else if(regex_match(color, "^^(([0-1][0-9][0-9]|2([0-4][0-9]|5[0-5]))[^^\d]){2}(([0-1][0-9][0-9]|2([0-4][0-9]|5[0-5]))$", regexReturn, "", 0) >= REGEX_OK)
	{
		new i;
		new pos;
		new c;
		
		while((c = color[pos++]))
		{
			if(isdigit(c))
			{
				colors[i] *= 10;
				colors[i] += (c - '0');
			}
			else
			{
				i++;
			}
		}
	}
	else if(regex_match(color, "^^#?([0-9a-f]{3}){1,2}$", regexReturn, "", 0, "i") >= REGEX_OK)
	{
		// skip the # if exists
		new pos = (color[0] == '#');
		
		#define HexToInt(%1) (('0' <= %1 <= '9') ? (%1 - '0') : (('a' <= %1 <= 'f') ? (%1 - 'a' + 10) : (%1 - 'A' + 10)))
		
		// check if used shortcut, like #fff
		new bool:short = (strlen(color[pos]) == 3);
		
		for(new i = 0; i < 3; i++)
		{
			colors[i] = HexToInt(color[pos]) << 4;
			pos++;
			
			if(short)
			{
				colors[i] |= (colors[i] >> 4);
			}
			else
			{
				colors[i] |= HexToInt(color[pos]);
				pos++;
			}
		}
	}
	else
	{
		valid = 0;
	}
	
	r = colors[0];
	g = colors[1];
	b = colors[2];
	
	return valid;
}

stock html_encode(const string[], output[], output_len)
{
	if(!__set_html_len) __html_set_lengths();
	
	new len = copy(output, output_len, string);
	
	for(new i = 0, total; i < sizeof(__html_entities); i++)
	{
		total = str_replace(output, output_len, __html_entities[i][0], __html_entities[i][1]);
		
		if(total)
		{
			total *= __html_len[i];
			
			len += total;
		}
	}
	
	return len;
}

stock html_decode(const string[], output[], output_len)
{
	if(!__set_html_len) __html_set_lengths();
	
	new len = copy(output, output_len, string);
	
	for(new i = sizeof(__html_entities) - 1, total; i >= 0; i--)
	{
		total = str_replace(output, output_len, __html_entities[i][1], __html_entities[i][0]);
		
		if(total)
		{
			total *= __html_len[i];
			
			len -= total;
		}
	}
	
	return len;
}

stock __html_set_lengths()
{
	for(new i = 0; i < sizeof(__html_entities); i++)
	{
		__html_len[i] = strlen(__html_entities[i][1]) - strlen(__html_entities[i][0]);
	}
	
	__set_html_len = true;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1053\\ f0\\ fs16 \n\\ par }
*/
