package hxlazy;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;
using Lambda;

// All credits to Andreas Söderlund!

 class LazyBuilder 
{
	
	static var LAZY = 'lazy';
	static var LAZY_GET= 'lazyGet';
	
	public static function build():Array<Field>
	{
		var originalFields = Context.getBuildFields();
		var resultFields:Array<Field> = [];
		var lazyFields = originalFields.filter(function(f) return f.meta.exists(function(m) return m.name == LAZY));
		var lazyGetFields = originalFields.filter(function(f) return f.meta.exists(function(m) return m.name == LAZY_GET));
		var nonLazyFields = originalFields.filter(function(f) return ! lazyFields.has(f) && ! lazyGetFields.has(f));
		nonLazyFields.iter(function(f) resultFields.push(f));
		lazyFields.iter(function(f) resultFields = resultFields.concat(createLazyFields(f, LAZY)));
		lazyGetFields.iter(function(f) resultFields = resultFields.concat(createLazyFields(f, LAZY_GET)));
		return resultFields;
	}

	static private function createLazyFields(f:Field, metaName:String):Array<Field> 
	{
		var lazyfields:Array<Field> = [];
		var fieldName = f.name;
		var fieldType = switch f.kind {
			case FFun(f2): f2.ret;
			case _: 
				Context.warning("The 'lazy' meta...", f.pos);
				return [f];
		}

		var functionBody = switch f.kind 
		{
			case FFun(f2): f2.expr;
			case _: return [f];
		}
		
		var privateFieldName = '__lazy' + fieldName;
		var nullField = TPath( { name:'Null', pack:[], params:[TPType(fieldType)] } );
		lazyfields.push({
			name: privateFieldName,
			doc: null,
			access: [Access.APrivate],
			kind: FVar(nullField, null),
			pos: Context.currentPos()
		});

		var getMethodName:String;
		var getMethodAccess:Access;
		if (metaName == LAZY)
		{
			lazyfields.push({
				name: fieldName,
				doc: null,
				access: [Access.APublic],
				kind: FProp('get', 'never', fieldType, null),
				pos: Context.currentPos()
			});
			getMethodName = 'get_$fieldName';
			getMethodAccess = Access.APrivate;
		}
		else if (metaName == LAZY_GET)
		{
			var ufieldName = fieldName.substr(0, 1).toUpperCase() + fieldName.substr(1);
			getMethodName = 'get$ufieldName';
			getMethodAccess = Access.APublic;
		}

		lazyfields.push({
			name: getMethodName,
			doc: null,
			access: [getMethodAccess],
			kind: FFun(createLazyGetter(privateFieldName, functionBody)),
			pos: Context.currentPos()
		});

		return lazyfields;
	}
   
	static private function createLazyGetter(privateFieldName:String, functionBody:Expr) : Function
	{
		 var replaceReturnValue:Expr -> Void;
		 replaceReturnValue = function(e:Expr) {
			 switch e {
				 case macro return $retval: 
					var change = macro return $i{privateFieldName} = $retval;
					e.expr = change.expr;
				case _: e.iter(replaceReturnValue);
			 }
		 }

		 functionBody.iter(replaceReturnValue);

		 switch functionBody.expr {
			 case EBlock(exprs): 
				 exprs.unshift(macro if ( $i { privateFieldName } != null) return $i { privateFieldName } );
			// case OBS hantera fall där metoden saknar block!
			case _: 
		 }

		var result = {
			ret: null,
			params: [],
			expr: functionBody,
			args: []
		}
		   
		return result;  
	}
}