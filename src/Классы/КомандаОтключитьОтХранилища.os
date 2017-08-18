
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем Лог;
Перем ИспользуемаяВерсияПлатформы;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Отключить информационную базу от хранилища конфигураций");

	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "СтрокаПодключения", "Строка подключения к ИБ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-db-user",
		"Пользователь ИБ");
	
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-db-pwd",
		"Пароль пользователя ИБ");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-v8version",
    	"Маска версии платформы 1С");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
		"-uccode",
		"Ключ разрешения запуска ИБ");

    Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт
    
	СтрокаПодключения			= ПараметрыКоманды["СтрокаПодключения"];
	Пользователь				= ПараметрыКоманды["-db-user"];
	ПарольПользователя			= ПараметрыКоманды["-db-pwd"];
	ИспользуемаяВерсияПлатформы	= ПараметрыКоманды["-v8version"];
	КлючРазрешения				= ПараметрыКоманды["-uccode"];

	ВозможныйРезультат = МенеджерКомандПриложения.РезультатыКоманд();

	Если ПустаяСтрока(СтрокаПодключения) Тогда
		Лог.Ошибка("Не указана строка подключения к ИБ");
		Возврат ВозможныйРезультат.НеверныеПараметры;
	КонецЕсли;

	Попытка
		ОтключитьОтХранилища(СтрокаПодключения
						   , Пользователь
						   , ПарольПользователя
						   , КлючРазрешения);

		Возврат ВозможныйРезультат.Успех;
	Исключение
		Лог.Ошибка(ОписаниеОшибки());
		Возврат ВозможныйРезультат.ОшибкаВремениВыполнения;
	КонецПопытки;

КонецФункции

Процедура ОтключитьОтХранилища(Знач СтрокаПодключения
							 , Знач ИмяПользователя
							 , Знач ПарольПользователя
							 , Знач КлючРазрешения)

	Конфигуратор = ЗапускПриложений.НастроитьКонфигуратор(СтрокаПодключения
														, ИмяПользователя
														, ПарольПользователя
														, ИспользуемаяВерсияПлатформы);
	
	Если Не ПустаяСтрока(КлючРазрешения) Тогда
		Конфигуратор.УстановитьКлючРазрешенияЗапуска(КлючРазрешения);
	КонецЕсли;

	Конфигуратор.ОтключитьсяОтХранилища();

КонецПроцедуры

Лог = Логирование.ПолучитьЛог("ktb.app.cpdb");