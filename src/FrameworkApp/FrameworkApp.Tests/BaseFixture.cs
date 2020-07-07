using NUnit.Framework;

namespace FrameworkApp.Tests
{
    [TestFixture]
    public class BaseFixture
    {
        [TearDown]
        public void CleanupDb()
        {
            TestHelper.CleanupDb();
        }
    }
}