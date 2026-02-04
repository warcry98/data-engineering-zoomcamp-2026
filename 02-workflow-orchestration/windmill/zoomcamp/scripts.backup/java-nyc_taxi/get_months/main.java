//requirements:
//com.google.code.gson:gson:2.8.9
//com.github.ricksbrown:cowsay:1.1.0

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.github.ricksbrown.cowsay.Cowsay;
import com.github.ricksbrown.cowsay.plugin.CowExecutor;
import java.util.*;

public class Main {
  public static class Months {
    private String[] month;

    // Constructor
    public Months(String[] month) {
        this.month = month;
    }
  }

  public static Object main(
    String year
    ){
    Gson gson = new Gson();
    System.out.println("Year: " + year);

    String[] months;
    switch (year) {
      case "2019":
      case "2020":
        months = new String[12];
        for (int i = 0; i < 12; i++) {
          months[i] = String.format("%02d", i + 1);
        }
        break;
      case "2021":
        months = new String[7];
        for (int i = 0; i < 7; i++) {
          months[i] = String.format("%02d", i + 1);
        }
        break;
      default:
        throw new IllegalArgumentException("Unsupported year: " + year);
    }
    Months monthList = new Months(months);
    System.out.println(monthList);

    // Serialize the Months object to JSON
    String json = gson.toJson(monthList);
    System.out.println("Serialized JSON: " + json);

    return json;
  }
}