package com.manaloom.forge;

import forge.GuiDesktop;
import forge.gui.GuiBase;
import forge.util.MyRandom;
import forge.view.SimulateMatch;

import java.util.Random;

public final class SeededForgeMain {
    private SeededForgeMain() {
    }

    public static void main(String[] args) {
        String seedValue = System.getProperty("manaloom.seed");
        if (seedValue != null && !seedValue.isBlank()) {
            MyRandom.setRandom(new Random(Long.parseLong(seedValue)));
        }

        System.setProperty("java.util.Arrays.useLegacyMergeSort", "true");
        System.setProperty("sun.java2d.d3d", "false");
        GuiBase.setInterface(new GuiDesktop());

        try {
            SimulateMatch.simulate(args);
            System.out.flush();
            System.err.flush();
            System.exit(0);
        } catch (Throwable error) {
            error.printStackTrace(System.err);
            System.err.flush();
            System.exit(1);
        }
    }
}
