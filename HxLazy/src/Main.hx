import hxlazy.Lazy;
using Lambda;
class Main
{
	static function main()
	{
		var t:TestLazy = new TestLazy();
		trace(t.sum);
		trace(t.sum);
		trace(t.helloWorld);
		trace(t.helloWorld);
		trace(t.getTestfloat());
		
	}
}
 
class TestLazy implements Lazy
{
	public function new() { }
	
	@lazy public function sum():Int
	{
		trace('Init sum - should only be traced once');
		return 1 + 2 + 3 + 4;
	}
	
	@lazy public function helloWorld():String
	{
		var msg = 'Hello ' + 'World!';
		trace('Init helloWorld - should only be traced once');
		return msg;
	}

	@lazyGet public function testfloat():Float
	{
		trace('Init testFloat - should only be traced once');
		return 1.2 + 3.4;
	}
	
	
	
}