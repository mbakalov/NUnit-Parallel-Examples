using System.Reflection;
using NUnit.Framework;

namespace FrameworkApp.Tests
{
    //[Parallelizable(ParallelScope.All)]
    public class Fixture0: BaseFixture
    {
        [Test]
        public void Test0()
        {
            TestHelper.RunTest(GetType().Name, MethodBase.GetCurrentMethod().Name);
        }

        [Test]
        public void Test1()
        {
            TestHelper.RunTest(GetType().Name, MethodBase.GetCurrentMethod().Name);
        }

        [Test]
        public void Test2()
        {
            TestHelper.RunTest(GetType().Name, MethodBase.GetCurrentMethod().Name);
        }

        [Test]
        public void Test3()
        {
            TestHelper.RunTest(GetType().Name, MethodBase.GetCurrentMethod().Name);
        }
    }
}