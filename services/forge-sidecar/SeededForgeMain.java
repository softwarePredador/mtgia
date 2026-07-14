package com.manaloom.forge;

import forge.util.MyRandom;

import java.util.Random;

public final class SeededForgeMain {
    private SeededForgeMain() {
    }

    public static void main(String[] args) {
        String seedValue = System.getProperty("manaloom.seed");
        if (seedValue != null && !seedValue.isBlank()) {
            MyRandom.setRandom(new Random(Long.parseLong(seedValue)));
        }
        forge.view.Main.main(args);
    }
}
