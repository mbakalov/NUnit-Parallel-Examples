using System;
using System.Linq;
using FrameworkApp.Logic;
using FrameworkApp.Logic.DAL;
using NUnit.Framework;

namespace FrameworkApp.Tests
{
    public static class TestHelper
    {
        private const int UserCount = 4;
        private const int PostByEachUser = 4;
        private const int CommentByPost = 10;

        public static void RunTest(string fixtureName, string methodName)
        {
            var db = new BlogContext(TestContext.Parameters.Get("DbName", "BlogContext"));
            var testName = $"{fixtureName}.{methodName}";
            for (int i = 0; i < UserCount; i++)
            {
                var u = new User { Name = $"{testName} User {i}", CreatedOn = DateTime.Now };
                db.Users.Add(u);

                for (int j = 0; j < PostByEachUser; j++)
                {
                    var p = new Post { Body = $"{testName} Post {j} by User {i}", CreatedOn = DateTime.Now, Owner = u };
                    db.Posts.Add(p);
                }
            }

            db.SaveChanges();

            var users = db.Users.ToList();
            foreach (var p in db.Posts.ToList())
            {
                foreach (var u in users)
                {
                    for (int k = 0; k < CommentByPost; k++)
                    {
                        var c = new Comment
                        {
                            Author = u,
                            ParentPost = p,
                            CreatedOn = DateTime.Now,
                            Text = $"{testName}. Comment {k} on Post {p} by User {u}"
                        };
                        db.Comments.Add(c);
                    }
                }
            }

            db.SaveChanges();

            Assert.AreEqual(UserCount * PostByEachUser * UserCount * CommentByPost, db.Comments.Count(), "Comment count");
        }

        public static void CleanupDb()
        {
            var db = new BlogContext(TestContext.Parameters.Get("DbName", "BlogContext"));
            db.Database.ExecuteSqlCommand("DELETE FROM Comments");
            db.Database.ExecuteSqlCommand("DELETE FROM Posts");
            db.Database.ExecuteSqlCommand("DELETE FROM Users");
        }
    }
}