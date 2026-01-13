package com.pergamino.core.ui

import android.content.Intent

fun Intent.clearTaskAndStartNew(): Intent {
    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
    return this
}
