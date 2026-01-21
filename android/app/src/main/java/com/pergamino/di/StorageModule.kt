package com.pergamino.di

import com.pergamino.data.local.SecureDeviceStorage
import com.pergamino.data.local.SecureDeviceStorageImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class StorageModule {

    @Binds
    @Singleton
    abstract fun bindSecureDeviceStorage(
        impl: SecureDeviceStorageImpl
    ): SecureDeviceStorage
}
