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

import android.content.Context;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.content.res.Resources.Theme;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.graphics.PorterDuff;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.TransitionDrawable;
import android.os.Build;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.Gravity;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.RelativeLayout;

import java.io.IOException;
import java.io.InputStream;
import java.util.concurrent.ConcurrentHashMap;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;

import android.support.v4.view.MenuItemCompat;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBar;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.widget.Toolbar;


class Actionable
{

    private static AssetManager sAssetMgr;

    private static Context ctx;

    private String mTitle;

    private Boolean mDisabled;

    private int mFlags;

    private Drawable mIcon;

    private Boolean mPrimary;

    private Boolean mSelected;

    private String mCallbackId;

    private int mOrder = 0;


    public static Actionable fromJSON(JSONObject jsobj)
    {
        try
        {
            Actionable action = new Actionable();
            action.mTitle = jsobj.getString("label");
            action.mDisabled = jsobj.optBoolean("disabled", false);
            action.mSelected = jsobj.optBoolean("selected", false);
            action.mPrimary = jsobj.optBoolean("primary", false);

            action.mCallbackId = jsobj.optString("callback");

            String iconname = jsobj.optString("icon", null);

            if (iconname != null) {
                try
                {
                    String tmp_uri = "www/" + iconname;
                    InputStream image = sAssetMgr.open(tmp_uri);

                    Bitmap bmp = BitmapFactory.decodeStream(image);
                    DisplayMetrics dm = ctx.getResources().getDisplayMetrics();
                    bmp.setDensity(dm.densityDpi);
                    action.mIcon = new BitmapDrawable(ctx.getResources(), bmp);
                }
                catch (IOException e)
                {
                }
            }

            return action;
        }
        catch (JSONException e)
        {
            LOG.e("Cambie", Log.getStackTraceString(e));
            return null;
        }
    }

    public static void setAssetManager(AssetManager mgr, Context context)
    {
        sAssetMgr = mgr;
        ctx = context;
    }

    public String getCallbackId()
    {
        return mCallbackId;
    }

    public int getFlags()
    {
        return this.mFlags;
    }

    public Drawable getIcon()
    {
        return this.mIcon;
    }

    public int getOrder()
    {
        return this.mOrder;
    }

    public String getTitle()
    {
        return this.mTitle;
    }

    public Boolean isDisabled()
    {
        return this.mDisabled;
    }

    public Boolean isPrimary()
    {
        return this.mPrimary;
    }

    public Boolean isSelected()
    {
        return this.mSelected;
    }

    public void setFlags(int flags)
    {
        this.mFlags = flags;
    }

    public void setOrder(int order)
    {
        this.mOrder = order;
    }
}


public class CambiePlugin extends CordovaPlugin
{
    private final String TAG = "CambiePlugin";

    protected ActionBarActivity mActivity;

    /** The view that wraps both the webview and the drawer list. */
    protected DrawerLayout mDrawerWrapper;

    /** The drawer toggle button. */
    protected ActionBarDrawerToggle mDrawerToggle;

    /** The list view for the drawer navigation. */
    protected ListView mDrawerList;

    /** The adapter for providing the drawer list view items. */
    protected CambieDrawerAdapter mDrawerAdapter;

    /** The toolbar-based ActionBar if we're using it. */
    protected Toolbar mToolbar;

    /** The colour of the ActionBar. */
    protected Integer mColor;

    /** Whether the drawer is enabled at the top level or not. */
    protected Boolean mDrawerEnabled;

    /** The AssetManager for accessing images in the www folder. */
    private AssetManager mAssets;

    /** The menu items and action items shown in the ActionBar. */
    private ConcurrentHashMap<String, Actionable> mActions;


    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);

        LOG.v(TAG, "Initializing");

        mColor = null;
        mActivity = (ActionBarActivity)cordova.getActivity();
        mAssets = mActivity.getAssets();

        mActions = new ConcurrentHashMap<String, Actionable>();
        mDrawerAdapter = new CambieDrawerAdapter(mActivity, webView);
        mDrawerEnabled = null;

        Actionable.setAssetManager(mAssets, (Context)mActivity);

        initViews();
    }


    //- VIEW HACKERY ----------------------------------------------------------

    protected void initViews()
    {
        final String navtype = preferences.getString("CambieNavType", "drawer");
        final Integer bg = preferences.getInteger("BackgroundColor", Color.BLACK);

        mColor = bg;

        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Boolean useToolbar = preferences.getBoolean("CambieUseToolbar", false);

                // When the plugin is initialized, we are at a point where it
                // is safe to do our view magic. The first question is to
                // figure out what kind of view magic we need to do, based on
                // what type of navigation we are showing.
                View mainView;
                if (navtype.toLowerCase().equals("tabs")) {
                    useToolbar = false; // Can't have toolbar and tabs
                    mainView = createAppView(useToolbar);
                } else {
                    mainView = createDrawerView(useToolbar);
                }
                mActivity.setContentView(mainView);

                mainView.setBackgroundColor(bg);

                // Set the Toolbar as the ActionBar if desired
                if (useToolbar) {
                    mColor = bg;
                    mToolbar.setBackgroundColor(mColor);
                    mActivity.setSupportActionBar(mToolbar);
                }

                ActionBar bar = mActivity.getSupportActionBar();

                if (navtype.toLowerCase().equals("tabs")) {
                    if (bar != null) {
                        bar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);
                    }
                } else {
                    /* Set up the Drawer Toggle */
                    mDrawerToggle = new ActionBarDrawerToggle(
                                            mActivity,
                                            mDrawerWrapper,
                                            android.R.string.ok,
                                            android.R.string.cancel) {

                        /**
                         * Called when a drawer has settled in a completely
                         * closed state.
                         */
                        public void onDrawerClosed(View view) {
                            super.onDrawerClosed(view);
                            mActivity.invalidateOptionsMenu();
                        }

                        /**
                         * Called when a drawer has settled in a completely
                         * open state.
                         */
                        public void onDrawerOpened(View drawerView) {
                            super.onDrawerOpened(drawerView);
                            mActivity.invalidateOptionsMenu();
                        }
                    };

                    mDrawerWrapper.setDrawerListener(mDrawerToggle);

                    // Fix for the icon getting into a confused state
                    mDrawerToggle.syncState();
                }

                // bar might be null if the theme doesn't show the action bar
                if (bar != null) {
                    if ((mDrawerEnabled != null && mDrawerEnabled) || webView.canGoBack()) {
                        bar.setDisplayHomeAsUpEnabled(true);
                        bar.setHomeButtonEnabled(true);
                    } else {
                        bar.setDisplayHomeAsUpEnabled(false);
                        bar.setHomeButtonEnabled(false);
                    }

                    if (mDrawerToggle != null) {
                        mDrawerToggle.setDrawerIndicatorEnabled(mDrawerEnabled != null && mDrawerEnabled && !webView.canGoBack());
                        mDrawerToggle.syncState();

                        if (mDrawerEnabled == null || !mDrawerEnabled) {
                            mDrawerWrapper.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
                        }
                    }

                    Boolean visible = preferences.getBoolean("CambieVisible", true);
                    if (!visible) {
                        bar.hide();
                    }
                }
            }
        });
    }

    protected View createDrawerView(Boolean useToolbar)
    {
        Integer bg = preferences.getInteger("CambieDrawerBackground", Color.WHITE);

        int drawerWidth = (int)TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, 260,
                mActivity.getResources().getDisplayMetrics());

        mDrawerWrapper = new DrawerLayout(mActivity);
        mDrawerWrapper.setLayoutParams(
                new DrawerLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

        View appRoot = createAppView(useToolbar);

        mDrawerList = new ListView(mActivity);
        mDrawerList.setAdapter(mDrawerAdapter);
        mDrawerList.setOnItemClickListener(mDrawerAdapter);
        mDrawerList.setBackgroundColor(bg);

        mDrawerWrapper.addView(appRoot, 0,
                new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT));

        mDrawerWrapper.addView(mDrawerList, 1,
                new DrawerLayout.LayoutParams(
                    drawerWidth,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    Gravity.LEFT));

        return mDrawerWrapper;
    }


    protected View createAppView(Boolean useToolbar)
    {
        ViewGroup appRoot;

        if (useToolbar) {
            RelativeLayout rlayout = new RelativeLayout(mActivity);

            rlayout.setLayoutParams(new RelativeLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT));

            appRoot = rlayout;
        } else {
            FrameLayout flayout = new FrameLayout(mActivity);
            flayout.setLayoutParams(new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT, 0.f));

            appRoot = flayout;
        }

        // Now we need to add the WebView
        ViewGroup oldRoot = (ViewGroup)webView.getView().getParent();
        oldRoot.removeView(webView.getView());

        appRoot.addView(webView.getView(), 0);

        if (useToolbar) {
            // If we're using toolbar mode, we need to add that to the view
            // rather than just allowing the ActionBar to happen
            mToolbar = new Toolbar(mActivity);
            mToolbar.setLayoutParams(new Toolbar.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT));

            appRoot.addView(mToolbar, 1);
        }

        return appRoot;
    }



    //- CORDOVA PLUGIN INTERFACE ----------------------------------------------

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callback)
    {

        try {
            if (action.equals("show")) {
                mActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        ActionBar bar = mActivity.getSupportActionBar();
                        if (bar != null) {
                            bar.show();
                        }
                    }
                });

                callback.success();
                return true;
            }

            if (action.equals("hide")) {
                mActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        ActionBar bar = mActivity.getSupportActionBar();
                        if (bar != null) {
                            bar.hide();
                        }
                    }
                });

                callback.success();
                return true;
            }

            if (action.equals("setTitle")) {
                String title = args.getString(0);

                if (title == null) {
                    callback.error("Bad Arguments");
                    return false;
                }

                setTitle(title);
                callback.success();
                return true;
            }

            if (action.equals("setColor")) {
                String color = args.getString(0);

                if (color == null) {
                    callback.error("Bad Arguments");
                    return false;
                }

                Integer value = CambieColor.parse(color);
                setColor(value);
                callback.success();
                return true;
            }

            if (action.equals("setToolbarActions")) {
                JSONArray acts = args.getJSONArray(0);

                if (acts == null) {
                    callback.error("Bad Arguments");
                    return false;
                }

                mActions.clear();

                setToolbarActions(acts);
                callback.success();
                return true;
            }

            if (action.equals("setNavigationLinks")) {
                JSONArray acts = args.getJSONArray(0);

                if (acts == null) {
                    callback.error("Bad Arguments");
                    return false;
                }

                mActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        mDrawerAdapter.clear();
                    }
                });

                setNavigationLinks(acts);

                if (acts.length() > 0 && mDrawerEnabled == null) {
                    mDrawerEnabled = true;
                    mDrawerWrapper.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
                }

                callback.success();
                return true;
            }

            if (action.equals("enableNavigationLinks")) {
                // NoOp unless we have drawer items
                if (mDrawerAdapter.getCount() > 0) {
                    final String navtype = preferences.getString("CambieNavType", "drawer");
                    mDrawerEnabled = true;

                    mActivity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (navtype.equals("tabs")) {
                                ActionBar bar = mActivity.getSupportActionBar();
                                if (bar != null) {
                                    bar.setNavigationMode(ActionBar.NAVIGATION_MODE_TABS);
                                }
                            } else {
                                if (mDrawerToggle != null) {
                                    mDrawerToggle.setDrawerIndicatorEnabled(true);

                                    ActionBar bar = mActivity.getSupportActionBar();
                                    if (bar != null) {
                                        bar.setDisplayHomeAsUpEnabled(true);
                                        bar.setHomeButtonEnabled(true);
                                    }

                                    mDrawerToggle.syncState();
                                }
                                if (mDrawerWrapper != null) {
                                    mDrawerWrapper.setDrawerLockMode(DrawerLayout.LOCK_MODE_UNLOCKED);
                                }
                            }
                        }
                    });
                }

                callback.success();
                return true;
            }

            if (action.equals("disableNavigationLinks")) {
                // NoOp unless we have drawer items
                if (mDrawerAdapter.getCount() > 0) {
                    final String navtype = preferences.getString("CambieNavType", "drawer");
                    mDrawerEnabled = false;

                    mActivity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            if (navtype.equals("tabs")) {
                                ActionBar bar = mActivity.getSupportActionBar();
                                if (bar != null) {
                                    bar.setNavigationMode(ActionBar.NAVIGATION_MODE_STANDARD);
                                }
                            } else {
                                if (mDrawerToggle != null) {
                                    mDrawerToggle.setDrawerIndicatorEnabled(false);

                                    ActionBar bar = mActivity.getSupportActionBar();
                                    if (bar != null && !webView.canGoBack()) {
                                        bar.setDisplayHomeAsUpEnabled(false);
                                        bar.setHomeButtonEnabled(false);
                                    }

                                    mDrawerToggle.syncState();
                                }

                                if (mDrawerWrapper != null) {
                                    mDrawerWrapper.setDrawerLockMode(DrawerLayout.LOCK_MODE_LOCKED_CLOSED);
                                }
                            }
                        }
                    });
                }

                callback.success();
                return true;
            }

            LOG.d(TAG, "Tried to call " + action + " with " + args.toString());

            callback.sendPluginResult(new PluginResult(PluginResult.Status.INVALID_ACTION));
            return false;
        } catch (JSONException e) {
            LOG.e(TAG, Log.getStackTraceString(e));

            callback.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
            return false;
        }
    }


    @Override
    public Object onMessage(String id, Object data)
    {
        if (id.equals("onOptionsItemSelected")) {
            final MenuItem item = (MenuItem)data;

            mActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mDrawerToggle != null) {
                        if (mDrawerToggle.onOptionsItemSelected(item)) {
                            return;
                        }
                    }

                    if (item.getItemId() == android.R.id.home) {
                        webView.backHistory();
                    } else if (mActions.containsKey(item.getTitle())) {
                        Actionable act = mActions.get(item.getTitle());

                        PluginResult res = new PluginResult(PluginResult.Status.OK);
                        res.setKeepCallback(true);
                        webView.sendPluginResult(res, act.getCallbackId());
                    } else {
                        LOG.v(TAG, "Selected unknown menu item: " + item.getTitle());
                    }
                }
            });
            return null;
        }

        if (id.equals("onCreateOptionsMenu") || id.equals("onPrepareOptionsMenu"))
        {
            Menu mnu = (Menu)data;

            mnu.clear();
            buildMenu(mnu);
            return null;
        }

        if (id.equals("onPostCreate")) {
            mActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mDrawerToggle != null) {
                        mDrawerToggle.syncState();
                    }
                }
            });
            return null;
        }

        if (id.equals("drawerClicked")) {
            mActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (mDrawerWrapper != null) {
                        mDrawerWrapper.closeDrawers();
                    }
                }
            });
        }

        return null;
    }


    @Override
    public void onConfigurationChanged(final Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mDrawerToggle != null) {
                    mDrawerToggle.onConfigurationChanged(newConfig);
                }
            }
        });
    }


    //- UPDATE METHODS --------------------------------------------------------

    private void setTitle(final String title) {
        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Boolean showBack    = webView.canGoBack();
                Boolean showDrawer  = mDrawerEnabled != null && mDrawerEnabled && !showBack;
                ActionBar bar       = mActivity.getSupportActionBar();

                if (bar != null) {
                    bar.setTitle(title);

                    bar.setDisplayHomeAsUpEnabled(showBack || showDrawer);
                    bar.setHomeButtonEnabled(showBack || showDrawer);
                }

                if (mDrawerToggle != null) {
                    mDrawerToggle.setDrawerIndicatorEnabled(showDrawer);

                    // Fix for the icon getting into a confused state
                    mDrawerToggle.syncState();
                }
            }
        });
    }

    private void setColor(final Integer color) {
        final Integer darkened = CambieColor.darken(color);

        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (mColor != null) {
                    ColorDrawable begin = new ColorDrawable(mColor);
                    ColorDrawable end = new ColorDrawable(color);
                    ColorDrawable[] steps = { begin, end };
                    TransitionDrawable trans = new TransitionDrawable(steps);
                    trans.setCrossFadeEnabled(true);

                    if (mToolbar != null) {
                        mToolbar.setBackground(trans);
                    } else {
                        ActionBar bar = mActivity.getSupportActionBar();
                        if (bar != null) {
                            bar.setBackgroundDrawable(trans);
                        }
                    }

                    trans.startTransition(500);
                } else {
                    if (mToolbar != null) {
                        mToolbar.setBackgroundColor(color);
                    } else {
                        ColorDrawable bg = new ColorDrawable(color);
                        ActionBar bar = mActivity.getSupportActionBar();
                        if (bar != null) {
                            bar.setBackgroundDrawable(bg);
                        }
                    }
                }

                mColor = color;

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    mActivity.getWindow().setStatusBarColor(darkened);
                }

                // If it's a toolbar and it's not transparent, we want to push
                // the content down below it
                if (mToolbar != null) {
                    if (Color.alpha(color) == 255) {
                        TypedValue tv = new TypedValue();
                        Theme theme = mActivity.getTheme();
                        theme.resolveAttribute(android.R.attr.actionBarSize, tv, true);
                        int actionBarHeight = mActivity.getResources().getDimensionPixelSize(tv.resourceId);

                        RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams)webView.getView().getLayoutParams();
                        lp.setMargins(0, actionBarHeight, 0, 0);
                        webView.getView().setLayoutParams(lp);
                    } else {
                        RelativeLayout.LayoutParams lp = (RelativeLayout.LayoutParams)webView.getView().getLayoutParams();
                        lp.setMargins(0, 0, 0, 0);
                        webView.getView().setLayoutParams(lp);
                    }
                }
            }
        });
    }

    private void setToolbarActions(final JSONArray actions)
    {
        for (int i = 0; i < actions.length(); i++)
        {
            try
            {
                JSONObject btn = actions.getJSONObject(i);
                Actionable action = Actionable.fromJSON(btn);
                int flags = 0;

                if (action.getIcon() == null) {
                    flags |= MenuItemCompat.SHOW_AS_ACTION_WITH_TEXT;
                }

                if (action.isPrimary() != false) {
                    flags |= MenuItemCompat.SHOW_AS_ACTION_ALWAYS;
                }

                action.setFlags(flags);
                action.setOrder(i);

                mActions.put(action.getTitle(), action);
            }
            catch (Exception e)
            {
                LOG.e(TAG, Log.getStackTraceString(e));
            }
        }

        mActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mActivity.invalidateOptionsMenu();
            }
        });
    }

    private void setNavigationLinks(final JSONArray actions)
    {

        for (int i = 0; i < actions.length(); i++)
        {
            try
            {
                JSONObject btn = actions.getJSONObject(i);
                final Actionable action = Actionable.fromJSON(btn);

                /*if (btn.optBoolean("heading")) {
                    action.setFlags(CambieDrawerAdapter.ACTIONABLE_LIST_HEADER);
                }*/

                mActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        mDrawerAdapter.add(action);
                    }
                });
            }
            catch (Exception e)
            {
                LOG.e(TAG, Log.getStackTraceString(e));
            }
        }

        String navtype = preferences.getString("CambieNavType", "drawer");
        if (navtype.equals("tabs")) {
            // TODO: Make tabs
        } else {
            mActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    mDrawerAdapter.notifyDataSetChanged();
                }
            });
        }
    }


    public void buildMenu(Menu mnu)
    {
        if (mDrawerWrapper != null && mDrawerWrapper.isDrawerOpen(Gravity.LEFT)) {
            return;
        }

        for (Actionable act : mActions.values())
        {
            MenuItem mi = mnu.add(Menu.NONE, Menu.NONE, act.getOrder(), act.getTitle());

            mi.setTitleCondensed(act.getTitle());
            MenuItemCompat.setShowAsAction(mi, act.getFlags());

            if (act.isDisabled())
            {
                mi.setEnabled(false);
            }

            if (act.getIcon() != null)
            {
                TypedValue colourVal = new TypedValue();
                Theme theme = mActivity.getTheme();
                theme.resolveAttribute(android.R.attr.actionMenuTextColor, colourVal, true);
                int colourTint = mActivity.getResources().getColor(colourVal.resourceId);

                Drawable icon = act.getIcon();
                icon.mutate().setColorFilter(colourTint, PorterDuff.Mode.SRC_IN);
                mi.setIcon(act.getIcon());
            }
        }
    }
}
