using System.Data.Entity;

namespace FrameworkApp.Logic.DAL
{
    public class BlogContext: DbContext
    {
        public BlogContext() : base("BlogContext")
        {
            //Database.SetInitializer(new NullDatabaseInitializer<BlogContext>());
        }

        public BlogContext(string name) : base(name)
        {
            //Database.SetInitializer(new NullDatabaseInitializer<BlogContext>());
        }

        public DbSet<User> Users { get; set; }

        public DbSet<Post> Posts { get; set; }

        public DbSet<Comment> Comments { get; set; }
    }
}