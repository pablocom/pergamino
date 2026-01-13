package com.pergamino.feature.auth.di

import com.pergamino.feature.auth.data.datasource.AuthLocalDataSource
import com.pergamino.feature.auth.data.datasource.AuthLocalDataSourceImpl
import com.pergamino.feature.auth.data.datasource.AuthRemoteDataSource
import com.pergamino.feature.auth.data.datasource.FakeAuthRemoteDataSource
import com.pergamino.feature.auth.data.repository.AuthRepositoryImpl
import com.pergamino.feature.auth.domain.repository.AuthRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class AuthModule {

    @Binds
    @Singleton
    abstract fun bindAuthRepository(impl: AuthRepositoryImpl): AuthRepository

    @Binds
    @Singleton
    abstract fun bindAuthLocalDataSource(impl: AuthLocalDataSourceImpl): AuthLocalDataSource

    @Binds
    @Singleton
    abstract fun bindAuthRemoteDataSource(impl: FakeAuthRemoteDataSource): AuthRemoteDataSource
}
