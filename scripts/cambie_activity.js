#!/usr/bin/env node
var path = require('path');
var fs = require('fs');
var Common = require('cordova-common');

function cambieActivity(context) {
    // Do all the hacky find&replace stuff to change CordovaActivity to
    // CambieActivity so that it will properly extend ActionBarActivity
    if (context.opts.cordova.platforms.indexOf('android') !== -1) {
        // var xml = context.requireCordovaModule('cordova-lib/src/util/xml-helpers');
        var xml = Common.xmlHelpers;

        var project_path = path.join(context.opts.projectRoot, 'platforms', 'android', 'app', 'src', 'main');

        var manifest_path = path.join(project_path, 'AndroidManifest.xml');
        var manifest = xml.parseElementtreeSync(manifest_path);

        var pkg = manifest._root.attrib['package'];
        var activity = manifest.getroot().findall('./application/activity[@android:name]');

        if (activity.length < 1) {
            throw new Error("No Activity defined?");
        }

        var clsfile = 'java.' + pkg + '.' + activity[0].attrib['android:name'];
        clsfile = clsfile.replace(/\./g, path.sep) + '.java';

        var filepath = project_path + path.sep + clsfile;
        var file = fs.readFileSync(filepath, {encoding: 'utf8'});

        file = file.replace('org.apache.cordova.*;', 'org.apache.cordova.*;\nimport ca.dpogue.cambie.CambieActivity;');
        file = file.replace(/(class [A-Za-z0-9]+) extends CordovaActivity/, '$1 extends CambieActivity /* replaces extends CordovaActivity */');

        fs.writeFileSync(filepath, file, {encoding: 'utf8'});
    }
}

module.exports = cambieActivity;

