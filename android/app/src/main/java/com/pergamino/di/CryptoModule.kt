package com.pergamino.di

import com.pergamino.data.crypto.AndroidEcdsaKeyManager
import com.pergamino.data.crypto.EcdsaKeyManager
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class CryptoModule {

    @Binds
    @Singleton
    abstract fun bindEcdsaKeyManager(
        impl: AndroidEcdsaKeyManager
    ): EcdsaKeyManager
}
