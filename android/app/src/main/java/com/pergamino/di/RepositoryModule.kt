package com.pergamino.di

import com.pergamino.data.repository.EmailVerificationRepository
import com.pergamino.data.repository.EmailVerificationRepositoryImpl
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindEmailVerificationRepository(
        impl: EmailVerificationRepositoryImpl
    ): EmailVerificationRepository
}
