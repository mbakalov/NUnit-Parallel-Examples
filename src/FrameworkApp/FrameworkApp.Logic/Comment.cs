using System;

namespace FrameworkApp.Logic
{
    public class Comment
    {
        public int Id { get; set; }

        public string Text { get; set; }

        public DateTime CreatedOn { get; set; }

        public virtual Post ParentPost { get; set; }

        public virtual User Author { get; set; }
    }
}