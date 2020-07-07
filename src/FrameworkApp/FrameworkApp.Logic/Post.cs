using System;
using System.Collections.Generic;

namespace FrameworkApp.Logic
{
    public class Post
    {
        public int Id { get; set; }

        public string Body { get; set; }

        public DateTime CreatedOn { get; set; }

        public virtual User Owner { get; set; }

        public virtual ICollection<Comment> Comments { get; set; }

        public override string ToString()
        {
            return $"Post({Id}) by {Owner}";
        }
    }
}