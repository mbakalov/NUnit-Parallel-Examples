using System;
using System.Linq;
using System.Threading;
using FrameworkApp.Logic;
using FrameworkApp.Logic.DAL;

namespace FrameworkApp
{
    class Program
    {
        static void Main(string[] args)
        {
            //var db = new BlogContext();

            //RunDbProcesses("Main");

            var t = new Thread(() => RunDbProcesses("t1")) {Name = "t1"};
            t.Start();

            var t2 = new Thread(() => RunDbProcesses("t2")) { Name = "t2" };
            t2.Start();

            t.Join();
            t2.Join();
        }

        private static void RunDbProcesses(string threadName)
        {
            Console.Out.WriteLine($"Thread ({threadName}) started");

            const int UserCount = 5;
            const int PostByEachUser = 10;
            const int CommentByPost = 3;
            var db = new BlogContext();
            for (int i = 0; i < UserCount; i++)
            {
                var u = new User { Name = $"{threadName} User {i}", CreatedOn = DateTime.Now };
                db.Users.Add(u);

                for (int j = 0; j < PostByEachUser; j++)
                {
                    var p = new Post { Body = $"{threadName} Post {j} by User {i}", CreatedOn = DateTime.Now, Owner = u };
                    db.Posts.Add(p);
                }
            }

            db.SaveChanges();

            foreach (var p in db.Posts.ToList())
            {
                foreach (var u in db.Users.ToList())
                {
                    for (int k = 0; k < CommentByPost; k++)
                    {
                        var c = new Comment
                        {
                            Author = u,
                            ParentPost = p,
                            CreatedOn = DateTime.Now,
                            Text = $"{threadName}. Comment {k} on Post {p} by User {u}"
                        };
                        db.Comments.Add(c);
                    }
                }
            }

            db.SaveChanges();

            int expected = UserCount * PostByEachUser * UserCount * CommentByPost;
            Console.Out.WriteLine($"Thread ({threadName}) comment count: {db.Comments.Count()}, expected: {expected}");

            db.Database.ExecuteSqlCommand("DELETE FROM Comments");
            db.Database.ExecuteSqlCommand("DELETE FROM Posts");
            db.Database.ExecuteSqlCommand("DELETE FROM Users");
        }
    }
}
