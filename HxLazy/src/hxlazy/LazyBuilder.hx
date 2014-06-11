package hxlazy;

import haxe.macro.Context;
import haxe.macro.Expr;
using haxe.macro.ExprTools;
using Lambda;

// All credits to Andreas Söderlund!

 class LazyBuilder 
{

   public static function build():Array<Field>
   {
        var originalFields = Context.getBuildFields();
	var resultFields:Array<Field> = [];
	var lazyFields = originalFields.filter(function(f) return f.meta.exists(function(m) return m.name == 'lazy'));
	var nonLazyFields = originalFields.filter(function(f) return !lazyFields.has(f));
	lazyFields.iter(function(f) resultFields = resultFields.concat(createLazyFields(f)));
	nonLazyFields.iter(function(f) resultFields = resultFields.concat([f]));
        return resultFields;	   
   }
   
   static private function createLazyFields(f:Field):Array<Field> 
   {
	var lazyfields:Array<Field> = [];

	var fieldName = f.name;
	var fieldType = switch f.kind {
		case FFun(f2): f2.ret;
		case _: 
			Context.warning("The 'lazy' meta...", f.pos);
			return [f];
	}

	var functionBody = switch f.kind {
		case FFun(f2): f2.expr;
		case _: return [f];
	}	  

	//-----------------------------------------------------------------------------------------------------------------------
	// Create private variable for storing the method result
	var privateFieldName = '__lazy' + fieldName;
	var nullField = TPath( { name:'Null', pack:[], params:[TPType(fieldType)] } );
	lazyfields.push({
		name: privateFieldName,
		doc: null,
		access: [Access.APrivate],
		kind: FVar(nullField, null),
		pos: Context.currentPos()
	});	
	  
	//-----------------------------------------------------------------------------------------------------------------------
	// Create public property 
	lazyfields.push({
		name: fieldName,
		doc: null,
		access: [Access.APublic],
		kind: FProp('get', 'never', fieldType, null),
		pos: Context.currentPos()
	});		
	
	//-----------------------------------------------------------------------------------------------------------------------
	// Create private getter method, including the original method 
	lazyfields.push({
		name: 'get_$fieldName',
		doc: null,
		access: [Access.APrivate],
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