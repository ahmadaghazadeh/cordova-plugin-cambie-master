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

import android.app.Activity;
import android.content.Context;
import android.graphics.Color;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

class CambieDrawerAdapter extends BaseAdapter implements AdapterView.OnItemClickListener
{
    ArrayList<Actionable> mNavItems;
    HashMap<String, Integer> mNavMap;
    Context mContext;
    CordovaWebView mWebView;

    public static final int ACTIONABLE_LIST_HEADER = 1;


    public CambieDrawerAdapter(Context ctx, CordovaWebView webView) {
        mContext    = ctx;
        mWebView    = webView;
        mNavItems   = new ArrayList<Actionable>();
        mNavMap     = new HashMap<String, Integer>();
    }


    public void add(Actionable act) {
        if (mNavMap.containsKey(act.getTitle())) {
            return;
        }

        mNavItems.add(act);
        mNavMap.put(act.getTitle(), mNavItems.indexOf(act));

        Log.d("CambieDrawerAdapter", "Added " + act.getTitle());
    }

    public void remove(Actionable act) {
        Integer idx = mNavMap.get(act.getTitle());
        mNavItems.remove(idx);

        mNavMap.remove(act.getTitle());

        for (Map.Entry<String, Integer> entry : mNavMap.entrySet())
        {
            if (entry.getValue() > idx) {
                entry.setValue(entry.getValue() - 1);
            }
        }
    }

    public void clear() {
        mNavItems.clear();
        mNavMap.clear();
    }


    @Override
    public int getCount() {
        return mNavItems.size();
    }

    @Override
    public Object getItem(int position) {
        return mNavItems.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public boolean areAllItemsEnabled() {
        return false;
    }

    @Override
    public boolean isEnabled(int position) {
        try {
            Actionable item = mNavItems.get(position);

            return !item.isDisabled();
        } catch (IndexOutOfBoundsException e) {
            throw new ArrayIndexOutOfBoundsException(position);
        }
    }


    @Override
    public View getView(int position, View view, ViewGroup parent)
    {
        int resId;

        if (view == null) {
            LayoutInflater inf = (LayoutInflater)mContext.getSystemService(Activity.LAYOUT_INFLATER_SERVICE);
            resId = mContext.getResources().getIdentifier("drawer_item", "layout", mContext.getPackageName());

            view = inf.inflate(resId, null);
        }

        Actionable item = mNavItems.get(position);

        int tint = Color.BLACK;

        if (item.isDisabled()) {
            tint = Color.LTGRAY;
        }

        resId = mContext.getResources().getIdentifier("icon", "id", mContext.getPackageName());
        ImageView icon = (ImageView)view.findViewById(resId);
        if (item.getIcon() != null)
        {
            icon.setImageDrawable(item.getIcon());
            icon.setColorFilter(tint);
        }

        resId = mContext.getResources().getIdentifier("title", "id", mContext.getPackageName());
        TextView text = (TextView)view.findViewById(resId);

        text.setTextColor(tint);
        text.setText(item.getTitle());

        return view;
    }


    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        Actionable act = mNavItems.get(position);

        if (!act.isDisabled()) {
            PluginResult res = new PluginResult(PluginResult.Status.OK);
            res.setKeepCallback(true);
            mWebView.sendPluginResult(res, act.getCallbackId());

            mWebView.getPluginManager().postMessage("drawerClicked", null);
        }
    }
}
