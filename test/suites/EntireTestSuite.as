//------------------------------------------------------------------------------
//  Copyright (c) 2011 the original author or authors. All Rights Reserved. 
// 
//  NOTICE: You are permitted to use, modify, and distribute this file 
//  in accordance with the terms of the license agreement accompanying it. 
//------------------------------------------------------------------------------

package suites
{
import suites.UtilityPackageFunctionsSuite;

	[RunWith("org.flexunit.runners.Suite")]
	[Suite]
	public class EntireTestSuite
	{

		public var commandMapTestSuite:CommandMapTestSuite;

		public var contextBuilderTestSuite:ContextBuilderTestSuite;

		public var contextTestSuite:ContextTestSuite;

		public var guards_AND_hooksTestSuite:GuardsAndHooksTestSuite;
	
		public var typeMatchingTestSuite:TypeMatchingTestSuite;

		public var utilityPackageTestSuite:UtilityPackageFunctionsSuite;

		public var mediatorMapTestSuite:MediatorMapTestSuite;
		
		public var viewManagerTestSuite:ViewManagerTestSuite;

		public var eventMapTestSuite:EventMapTestSuite;
		
		public var commandFlowTestSuite:CommandFlowTestSuite;
		
		public var guardsTestSuite:GuardsTestSuite;
		
		public var hooksTestSuite:HooksTestSuite;
	}
}