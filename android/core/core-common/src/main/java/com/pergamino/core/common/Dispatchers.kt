package com.pergamino.core.common

import javax.inject.Qualifier

/**
 * Qualifier for the IO dispatcher used for disk and network operations.
 */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

/**
 * Qualifier for the Default dispatcher used for CPU-intensive work.
 */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

/**
 * Qualifier for the Main dispatcher used for UI operations.
 */
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class MainDispatcher
