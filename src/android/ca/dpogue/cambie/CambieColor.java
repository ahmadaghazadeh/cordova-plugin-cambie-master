/**
 * Copyright 2014 Darryl Pogue
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package ca.dpogue.cambie;

import android.graphics.Color;
import android.util.Log;

import java.util.regex.Pattern;
import java.util.regex.Matcher;


class CambieColor
{
    public static Integer parse(String color)
    {
        try {
            if (color.startsWith("rgba")) {
                Pattern c = Pattern.compile("rgba *\\( *([0-9]+), *([0-9]+), *([0-9]+), *([0-9\\.]+) *\\)");
                Matcher m = c.matcher(color);

                if (m.matches()) {
                    Float alpha = Float.valueOf(m.group(4)) * 255;
                    return Color.argb(alpha.intValue(),
                                      Integer.valueOf(m.group(1)),
                                      Integer.valueOf(m.group(2)),
                                      Integer.valueOf(m.group(3)));
                }
            }

            if (color.startsWith("rgb")) {
                Pattern c = Pattern.compile("rgb *\\( *([0-9]+), *([0-9]+), *([0-9]+) *\\)");
                Matcher m = c.matcher(color);

                if (m.matches()) {
                    return Color.rgb(Integer.valueOf(m.group(1)),
                                     Integer.valueOf(m.group(2)),
                                     Integer.valueOf(m.group(3)));
                }
            }

            if (color.startsWith("#")) {
                return Color.parseColor(color);
            }

            return Color.BLACK;
        } catch (IllegalArgumentException e) {
            Log.e("CambieColor", "Failed to parse " + color);

            return Color.BLACK;
        }
    }


    public static Integer darken(int color)
    {
        if (Color.alpha(color) < 255) {
            return color;
        }

        float[] hsv = new float[3];
        Color.colorToHSV(color, hsv);
        hsv[2] *= 0.8f; // value component
        return Color.HSVToColor(hsv);
    }


    public static Integer textColor(int color)
    {
        Float r_comp = ((Color.red(color)   / 255.f) * 299.f);
        Float g_comp = ((Color.green(color) / 255.f) * 587.f);
        Float b_comp = ((Color.blue(color)  / 255.f) * 114.f);

        Float brightness = (r_comp + g_comp + b_comp) / 1000.f;

        if (brightness < 0.5) {
            return Color.WHITE;
        } else {
            return Color.BLACK;
        }
    }
}
