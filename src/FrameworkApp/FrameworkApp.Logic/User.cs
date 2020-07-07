using System;
using System.Collections.Generic;

namespace FrameworkApp.Logic
{
    public class User
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public DateTime CreatedOn { get; set; }

        public virtual ICollection<Post> Posts { get; set; }

        public virtual ICollection<Comment> Comments { get; set; }

        public override string ToString()
        {
            return $"User '{Name}' ({Id})";
        }
    }
}