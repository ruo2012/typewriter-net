using System;
using System.Collections.Generic;
using System.Text;

public class TextTable
{
	private List<List<string>> rows = new List<List<string>>();

	public TextTable()
	{
		rows.Add(new List<string>());
	}

	private int maxColWidth = 100;

	public TextTable SetMaxColWidth(int maxColWidth)
	{
		this.maxColWidth = maxColWidth;
		return this;
	}

	public TextTable Add(string text)
	{
		List<string> list = rows[rows.Count - 1];
		list.Add(text);
		return this;
	}

	public TextTable AddLine()
	{
		rows.Add(null);
		rows.Add(new List<string>());
		return this;
	}

	public TextTable NewRow()
	{
		rows.Add(new List<string>());
		return this;
	}
	
	public struct Splitted
	{
		public string head;
		public string tail;
		
		public Splitted(string head, string tail)
		{
			this.head = head;
			this.tail = tail;
		}
	}
	
	private Splitted SplitSubline(string text, int length)
	{
		int index = text.IndexOf('\n');
		if (index != -1 && index <= length)
			return new Splitted(text.Substring(0, index), text.Substring(index + 1));
		if (text.Length > length)
			return new Splitted(text.Substring(0, length), text.Substring(length));
		return new Splitted(text, null);
	}

	override public string ToString()
	{
		int colsCount = 0;
		int rowsCount = rows.Count;
		for (int i = 0; i < rowsCount; i++)
		{
			List<string> list = rows[i];
			if (list != null)
			{
				if (colsCount < list.Count)
					colsCount = list.Count;
			}
		}
		int[] colSizes = new int[colsCount];
		for (int i = 0; i < colsCount; i++)
		{
			for (int j = 0; j < rowsCount; j++)
			{
				List<string> list = rows[j];
				if (list != null)
				{
					string text = i < list.Count ? list[i] : "";
					int length = Math.Min(maxColWidth, text.Length);
					if (colSizes[i] < length)
						colSizes[i] = length;
				}
			}
		}
		int width = (colsCount - 1) * 3;
		for (int i = 0; i < colsCount; i++)
		{
			width += colSizes[i];
		}
		string[] lineTexts = new string[colsCount];
		StringBuilder builder = new StringBuilder();
		for (int i = 0; i < rowsCount; i++)
		{
			List<string> list = rows[i];
			if (list != null)
			{
				for (int j = 0; j < colsCount; j++)
				{
					lineTexts[j] = j < list.Count ? list[j] : "";
				}
				while (true)
				{
					bool allCompleted = true;
					for (int j = 0; j < colsCount; j++)
					{
						if (j > 0)
							builder.Append(" | ");
						if (lineTexts[j] != null)
						{
							Splitted splitted = SplitSubline(lineTexts[j], colSizes[j]);
							lineTexts[j] = splitted.tail;
							allCompleted = splitted.tail == null;
							builder.Append(splitted.head.PadRight(colSizes[j]));
						}
						else
						{
							builder.Append(new string(' ', colSizes[j]));
						}
					}
					builder.AppendLine();
					if (allCompleted)
						break;
				}
			}
			else
			{
				for (int j = 0; j < colsCount; j++)
				{
					if (j > 0)
						builder.Append("-+-");
					int colSize = colSizes[j];
					builder.Append(new string('-', colSize));
				}
				builder.AppendLine();
			}
		}
		return builder.ToString();
	}
}
