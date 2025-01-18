import Toybox.System;
import Toybox.Communications;
import Toybox.Lang;

class MultidayReviewPusher {

    hidden var mCallback; 
    hidden var mEntireObject;
    hidden var mLeftKeys;
    hidden var mGoalTexts as Array<String>;

    function initialize(callback as Method, entireObject, goalTexts as Dictionary<String, Array<Array<String>>>) {
        mCallback = callback;
        mEntireObject = entireObject;
        if (entireObject == null || mEntireObject.keys().size() == 0) {
            mLeftKeys = new [0];
            mGoalTexts = new [0];
            return;
        }
        mLeftKeys = mEntireObject.keys();
        mGoalTexts = new [goalTexts["goals"].size()];
        for (var i = 0;i < goalTexts["goals"].size(); i++) {
            mGoalTexts[i] = goalTexts["goals"][i][1];
        }
    }

    function onDone(success, data) as Void {
        if (!success) {
            mCallback.invoke(false, data);
            return;
        }
        mLeftKeys = mLeftKeys.slice(1, null);

        start();
    }

    function start() as Void {
        if (mLeftKeys.size() == 0) {
            mCallback.invoke(true, {});
            return;
        }

        var day = mLeftKeys[0];
        var reviewsArray = mEntireObject[day];


        var body = {};
        body["date"] = day;
        body["results"] = reviewsArray;
        body["goals"] = mGoalTexts;
        new ApiCall(method(:onDone)).pushReviewsForDays(body);
    }
}