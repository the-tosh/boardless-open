{

	var NAMES = {};
	function add_name (name, start_offset, end_offset){
		NAMES[start_offset] = {'name': name.join(''), 'start_offset': start_offset, 'end_offset': end_offset};
	}

}

// FormulaEditor grammatics

Node
	= NodeStart _? NodeFinish? { return NAMES; }

NodeFinish
	= Operator _? Node

NodeStart
	= Entity
	/ "(" _? Node _? ")"?

Operator
	= "+" / "-" / "*" / "/"

Entity
	= Variable / Integer

Variable "variable"
	= Quote? _? name:([a-zа-я0-9]i)+ _? Quote? {add_name(name, location().start.offset, location().end.offset)}

Integer "integer"
	= [0-9]+

_ "whitespace"
	= [ \t\n\r]*

Quote
	= '"' / "'" / "`"