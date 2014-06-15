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
		trace(t.wihtoutBlock);
		trace(t.wihtoutBlock);
		trace(t.wihtoutBlock2);
		trace(t.wihtoutBlock2);
		trace(t.getWithoutBlock3());
		trace(t.getWithoutBlock3());
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
	
	@lazy public function wihtoutBlock():String return retString();
	@lazy public function wihtoutBlock2():{x:Float} return retAnon();
	@lazyGet public function withoutBlock3():Int return retInt();
	
	private function retInt()
	{
		trace('Redundant method: retInt() - should only be called once');
		return 432;
	}
	private function retAnon()
	{
		trace('Redundant method: retAnon() - should only be called once');
		return {x: 1.234};
	}
	private function retString()
	{
		trace('Redundant method: retString() - should only be called once');
		return 'Hello from return method!';
	}
	
	
	
}