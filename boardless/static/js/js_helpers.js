function evalWith (to_eval, scope) {
	var result;

	with (scope) {
		result = eval(to_eval);
	}

	return result
}