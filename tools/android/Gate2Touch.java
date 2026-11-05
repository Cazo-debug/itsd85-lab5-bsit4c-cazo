package com.itsd85.toottubes.qa;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.UiAutomation;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;

/** Original test-only helper: injects two touchscreen pointers into the game. */
public final class Gate2Touch extends Instrumentation {
    private Bundle arguments;
    private UiAutomation automation;
    private int events;
    private long downTime;
    private boolean pointerDown;

    @Override public void onCreate(Bundle value) {
        super.onCreate(value);
        arguments = value;
        start();
    }

    private float number(String name, float fallback) {
        String value = arguments.getString(name);
        return value == null ? fallback : Float.parseFloat(value);
    }

    private void requireGameForeground() throws Exception {
        try (ParcelFileDescriptor descriptor = automation.executeShellCommand("dumpsys window");
             FileInputStream input = new FileInputStream(descriptor.getFileDescriptor())) {
            ByteArrayOutputStream text = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int count;
            while ((count = input.read(buffer)) != -1) text.write(buffer, 0, count);
            boolean focused = false;
            for (String line : text.toString("UTF-8").split("\n")) {
                if (line.contains("mCurrentFocus=") && line.contains("com.itsd85.toottubes.prototype")) focused = true;
            }
            if (!focused) throw new IllegalStateException("Game is not foreground; touch injection cancelled");
        }
    }

    private void send(int action, int count, float ax, float ay, float gx, float gy) {
        MotionEvent.PointerProperties[] properties = new MotionEvent.PointerProperties[count];
        MotionEvent.PointerCoords[] coordinates = new MotionEvent.PointerCoords[count];
        for (int index = 0; index < count; index++) {
            properties[index] = new MotionEvent.PointerProperties();
            properties[index].id = index;
            properties[index].toolType = MotionEvent.TOOL_TYPE_FINGER;
            coordinates[index] = new MotionEvent.PointerCoords();
            coordinates[index].x = index == 0 ? ax : gx;
            coordinates[index].y = index == 0 ? ay : gy;
            coordinates[index].pressure = 1;
            coordinates[index].size = 0.1f;
        }
        MotionEvent event = MotionEvent.obtain(downTime, SystemClock.uptimeMillis(), action,
                count, properties, coordinates, 0, 0, 1, 1, 0, 0, InputDevice.SOURCE_TOUCHSCREEN, 0);
        try {
            if (!automation.injectInputEvent(event, true)) throw new IllegalStateException("Touch was rejected");
            events++;
            if (action == MotionEvent.ACTION_DOWN) pointerDown = true;
            if (action == MotionEvent.ACTION_UP || action == MotionEvent.ACTION_CANCEL) pointerDown = false;
        } finally {
            event.recycle();
        }
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            float ax = number("aim_x", 240), ay = number("aim_y", 2000);
            float gx = number("gas_x", 840), gy = number("gas_y", 2100);
            float endX = number("end_x", ax), endY = number("end_y", ay);
            float gasEndX = number("gas_end_x", gx), gasEndY = number("gas_end_y", gy);
            int duration = Math.max(100, Math.min(10000, (int)number("duration_ms", 1500)));
            int rest = Math.max(300, Math.min(4000, (int)number("rest_ms", 1200)));
            int cycles = Math.max(1, Math.min(20, (int)number("cycles", 1)));
            for (int cycle = 0; cycle < cycles; cycle++) {
                requireGameForeground();
                downTime = SystemClock.uptimeMillis();
                send(MotionEvent.ACTION_DOWN, 1, ax, ay, gx, gy);
                send(MotionEvent.ACTION_POINTER_DOWN | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, ax, ay, gx, gy);
                long start = SystemClock.uptimeMillis();
                long nextFocusCheck = start + 250;
                float x = ax, y = ay, gasX = gx, gasY = gy;
                while (SystemClock.uptimeMillis() - start < duration) {
                    if (SystemClock.uptimeMillis() >= nextFocusCheck) {
                        requireGameForeground();
                        nextFocusCheck = SystemClock.uptimeMillis() + 250;
                    }
                    float fraction = Math.min(1, (SystemClock.uptimeMillis() - start) / (float)duration);
                    x = ax + (endX - ax) * fraction;
                    y = ay + (endY - ay) * fraction;
                    gasX = gx + (gasEndX - gx) * fraction;
                    gasY = gy + (gasEndY - gy) * fraction;
                    send(MotionEvent.ACTION_MOVE, 2, x, y, gasX, gasY);
                    SystemClock.sleep(50);
                }
                send(MotionEvent.ACTION_POINTER_UP | (1 << MotionEvent.ACTION_POINTER_INDEX_SHIFT), 2, x, y, gasX, gasY);
                send(MotionEvent.ACTION_UP, 1, x, y, gasX, gasY);
                SystemClock.sleep(rest);
            }
            result.putString("passed", "true");
            result.putInt("events", events);
            finish(Activity.RESULT_OK, result);
        } catch (Exception error) {
            // Cancel outstanding pointers even when foreground validation fails.
            if (automation != null && pointerDown) {
                try { send(MotionEvent.ACTION_CANCEL, 1, 0, 0, 0, 0); } catch (Exception ignored) { }
            }
            result.putString("passed", "false");
            result.putInt("events", events);
            result.putString("error", error.toString());
            finish(Activity.RESULT_CANCELED, result);
        }
    }
}
