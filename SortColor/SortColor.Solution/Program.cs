using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SortColor.Solution
{
    class Program
    {
        static void Main(string[] args)
        {
            List<IColorable> colorList = new List<IColorable>() { new red(), new white(), new blue(), new red() };

            colorList.Sort((x, y) => string.Compare(x.Color, y.Color));

            foreach (IColorable color in colorList)
            {
                Console.WriteLine(color.ToString());
            }
            Console.ReadLine();
        }
    }
}
